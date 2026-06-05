package main

import (
	"bufio"
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func newRouter(t *testing.T, mode string, local, remote string) *router {
	t.Helper()
	dir := t.TempDir()
	mf := filepath.Join(dir, "mode")
	if mode != "" {
		if err := os.WriteFile(mf, []byte(mode+"\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	return &router{
		cfg: config{
			localURL:    local,
			remoteURL:   remote,
			modeFile:    mf,
			localModels: map[string]bool{"qwen2.5-coder:3b": true},
		},
		client: &http.Client{},
	}
}

func TestPick(t *testing.T) {
	const local, remote = "http://L", "http://R"
	chunk := []byte(`{"model":"qwen2.5-coder:3b","messages":[]}`)
	big := []byte(`{"model":"qwen2.5-coder:14b","messages":[]}`)

	cases := []struct {
		name, mode, method string
		body               []byte
		want               string // leg
	}{
		{"steady routes chunk to remote", "steady", "POST", chunk, "remote"},
		{"burst routes chunk to local", "burst", "POST", chunk, "local"},
		{"burst keeps 14b on remote", "burst", "POST", big, "remote"},
		{"burst GET goes remote", "burst", "GET", nil, "remote"},
		{"burst unparseable goes remote", "burst", "POST", []byte("not json"), "remote"},
		{"missing mode file is steady", "", "POST", chunk, "remote"},
		{"garbage mode is steady", "wat", "POST", chunk, "remote"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			r := newRouter(t, c.mode, local, remote)
			_, leg := r.pick(c.method, c.body)
			if leg != c.want {
				t.Fatalf("mode=%q method=%s: got leg %q, want %q", c.mode, c.method, leg, c.want)
			}
		})
	}
}

// TestProxyStreaming wires two fake upstreams and asserts the router forwards
// to the right one, preserves the body, and streams SSE chunks through.
func TestProxyStreaming(t *testing.T) {
	hit := func(label string) *httptest.Server {
		return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
			b, _ := io.ReadAll(req.Body)
			if !bytes.Contains(b, []byte(`"model"`)) {
				t.Errorf("%s: body not forwarded: %q", label, b)
			}
			fl, _ := w.(http.Flusher)
			w.Header().Set("Content-Type", "text/event-stream")
			w.WriteHeader(http.StatusOK)
			for _, tok := range []string{"data: a\n\n", "data: b\n\n", "data: [DONE]\n\n"} {
				_, _ = io.WriteString(w, label+":"+tok)
				if fl != nil {
					fl.Flush()
				}
			}
		}))
	}
	localUp := hit("local")
	remoteUp := hit("remote")
	defer localUp.Close()
	defer remoteUp.Close()

	post := func(r *router, model string) string {
		t.Helper()
		mux := http.NewServeMux()
		mux.HandleFunc("/", r.handle)
		front := httptest.NewServer(mux)
		defer front.Close()
		resp, err := http.Post(front.URL+"/v1/chat/completions", "application/json",
			strings.NewReader(`{"model":"`+model+`","messages":[]}`))
		if err != nil {
			t.Fatal(err)
		}
		defer resp.Body.Close()
		var got bytes.Buffer
		sc := bufio.NewScanner(resp.Body)
		for sc.Scan() {
			got.WriteString(sc.Text())
		}
		return got.String()
	}

	rBurst := newRouter(t, "burst", localUp.URL, remoteUp.URL)
	if out := post(rBurst, "qwen2.5-coder:3b"); !strings.Contains(out, "local:data") {
		t.Fatalf("burst 3b should hit local upstream, got %q", out)
	}
	if out := post(rBurst, "qwen2.5-coder:14b"); !strings.Contains(out, "remote:data") {
		t.Fatalf("burst 14b should hit remote upstream, got %q", out)
	}
	rSteady := newRouter(t, "steady", localUp.URL, remoteUp.URL)
	if out := post(rSteady, "qwen2.5-coder:3b"); !strings.Contains(out, "remote:data") {
		t.Fatalf("steady 3b should hit remote upstream, got %q", out)
	}
}
