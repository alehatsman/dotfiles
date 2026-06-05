// dex-summary-router — a tiny model-name-routing reverse proxy that sits in
// front of dex's DEX_SUMMARY_URL so a single dex drainer can fan its summary
// chat calls across two GPUs.
//
// dex (the drainer) POSTs OpenAI /v1/chat/completions with a JSON body that
// carries the model name. This proxy peeks that name and routes per a mode
// read fresh from a file on every request (so the mode flips with no restart):
//
//	steady (default): every request -> REMOTE upstream (mini_pc 5080 tunnel).
//	                  Behaviourally identical to pointing dex straight at REMOTE.
//	burst:            requests whose model is in -local-models go to LOCAL
//	                  (the 5090's ollama); everything else -> REMOTE. This lends
//	                  the high-volume chunk tier (3b) to the otherwise
//	                  foreground-only 5090 while the heavier tiers stay on 5080.
//
// Anything that isn't a model-bearing POST (health checks, GETs, unparseable
// bodies) falls through to REMOTE — the proxy is fail-safe toward the steady
// path, so a malformed mode file or a surprise request shape never strands the
// drainer.
//
// Stdlib only by design (boring tech, no deps): the fleet already has a Go
// toolchain for dex, and the routing decision is too body-dependent for an
// off-the-shelf proxy without scripting.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

// config is resolved once at startup from flags (which default to env vars).
// The mode is intentionally NOT here — it is re-read per request from modeFile.
type config struct {
	addr        string
	localURL    string
	remoteURL   string
	modeFile    string
	localModels map[string]bool
}

func main() {
	cfg := loadConfig()

	rp := &router{cfg: cfg, client: &http.Client{
		// No timeout: summaries stream and dex enforces its own per-call
		// deadline via the request context, which we propagate. A timeout
		// here would truncate long generations mid-stream.
		Timeout: 0,
	}}

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, "ok\n")
	})
	mux.HandleFunc("/", rp.handle)

	srv := &http.Server{Addr: cfg.addr, Handler: mux}
	log.Printf("dex-summary-router listening on %s (local=%s remote=%s mode-file=%s local-models=%v)",
		cfg.addr, cfg.localURL, cfg.remoteURL, cfg.modeFile, keys(cfg.localModels))
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("serve: %v", err)
	}
}

func loadConfig() config {
	def := func(env, fallback string) string {
		if v := os.Getenv(env); v != "" {
			return v
		}
		return fallback
	}
	addr := flag.String("addr", def("DEX_ROUTER_ADDR", "127.0.0.1:11436"), "listen address")
	local := flag.String("local-url", def("DEX_ROUTER_LOCAL_URL", "http://127.0.0.1:11434"), "LOCAL upstream (this box's ollama / 5090)")
	remote := flag.String("remote-url", def("DEX_ROUTER_REMOTE_URL", "http://127.0.0.1:11435"), "REMOTE upstream (summary tunnel / 5080)")
	modeFile := flag.String("mode-file", def("DEX_ROUTER_MODE_FILE", os.ExpandEnv("$HOME/.config/dex/summary-router.mode")), "file holding the current mode (steady|burst)")
	localModels := flag.String("local-models", def("DEX_ROUTER_LOCAL_MODELS", "qwen2.5-coder:3b"), "comma-separated models routed to LOCAL in burst mode")
	flag.Parse()

	lm := map[string]bool{}
	for _, m := range strings.Split(*localModels, ",") {
		if m = strings.TrimSpace(m); m != "" {
			lm[m] = true
		}
	}
	return config{
		addr:        *addr,
		localURL:    strings.TrimRight(*local, "/"),
		remoteURL:   strings.TrimRight(*remote, "/"),
		modeFile:    *modeFile,
		localModels: lm,
	}
}

type router struct {
	cfg    config
	client *http.Client
}

// mode reads the current mode fresh from disk. Missing/unreadable/unknown all
// resolve to "steady" — the safe, all-to-REMOTE default.
func (r *router) mode() string {
	b, err := os.ReadFile(r.cfg.modeFile)
	if err != nil {
		return "steady"
	}
	switch m := strings.ToLower(strings.TrimSpace(string(b))); m {
	case "burst":
		return "burst"
	default:
		return "steady"
	}
}

// peekModel buffers the body, extracts the OpenAI `model` field, and returns
// the buffered bytes so the caller can re-send them upstream. On any parse
// error it returns ("", body) and the caller routes to REMOTE.
func peekModel(body []byte) string {
	var probe struct {
		Model string `json:"model"`
	}
	if err := json.Unmarshal(body, &probe); err != nil {
		return ""
	}
	return probe.Model
}

func (r *router) handle(w http.ResponseWriter, req *http.Request) {
	body, err := io.ReadAll(req.Body)
	_ = req.Body.Close()
	if err != nil {
		http.Error(w, "read body: "+err.Error(), http.StatusBadGateway)
		return
	}

	target, leg := r.pick(req.Method, body)

	outURL := target + req.URL.Path
	if req.URL.RawQuery != "" {
		outURL += "?" + req.URL.RawQuery
	}
	out, err := http.NewRequestWithContext(req.Context(), req.Method, outURL, bytes.NewReader(body))
	if err != nil {
		http.Error(w, "build request: "+err.Error(), http.StatusBadGateway)
		return
	}
	copyHeaders(out.Header, req.Header)
	out.ContentLength = int64(len(body))

	start := time.Now()
	resp, err := r.client.Do(out)
	if err != nil {
		log.Printf("upstream %s error: %v", leg, err)
		http.Error(w, "upstream "+leg+": "+err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	copyHeaders(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)
	streamCopy(w, resp.Body)
	log.Printf("%s %s -> %s [%d] %s", req.Method, req.URL.Path, leg, resp.StatusCode, time.Since(start).Round(time.Millisecond))
}

// pick returns the upstream URL and a short leg label for logging.
func (r *router) pick(method string, body []byte) (string, string) {
	// Only model-bearing POSTs are candidates for LOCAL; everything else
	// (and steady mode) goes REMOTE.
	if method != http.MethodPost || r.mode() != "burst" {
		return r.cfg.remoteURL, "remote"
	}
	model := peekModel(body)
	if model != "" && r.cfg.localModels[model] {
		return r.cfg.localURL, "local"
	}
	return r.cfg.remoteURL, "remote"
}

// streamCopy copies the upstream body to the client, flushing after each chunk
// so SSE token streams arrive incrementally rather than buffered to EOF.
func streamCopy(w http.ResponseWriter, src io.Reader) {
	flusher, _ := w.(http.Flusher)
	buf := make([]byte, 32*1024)
	for {
		n, err := src.Read(buf)
		if n > 0 {
			if _, werr := w.Write(buf[:n]); werr != nil {
				return
			}
			if flusher != nil {
				flusher.Flush()
			}
		}
		if err != nil {
			return
		}
	}
}

func copyHeaders(dst, src http.Header) {
	for k, vs := range src {
		// Hop-by-hop headers must not be forwarded.
		switch http.CanonicalHeaderKey(k) {
		case "Connection", "Keep-Alive", "Proxy-Authenticate", "Proxy-Authorization",
			"Te", "Trailer", "Transfer-Encoding", "Upgrade":
			continue
		}
		for _, v := range vs {
			dst.Add(k, v)
		}
	}
}

func keys(m map[string]bool) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	return out
}
