# Dotfiles

Personal development environment configuration managed with [mooncake](https://github.com/alehatsman/mooncake) - a declarative configuration management tool.

## Features

- **Language Environments**: Python (pyenv), Rust (rustup), Node.js (nvm), Go
- **Shell Configuration**: Zsh with plugins (oh-my-zsh, zplug)
- **Terminal Tools**: tmux, fzf, git
- **Editors**: Neovim with Packer plugin manager
- **Platform Support**: macOS and Linux (Ubuntu/Debian)
- **Preset-Based**: Uses mooncake presets for clean, maintainable configs

## Prerequisites

- **Git**: For cloning the repository
- **Mooncake**: Configuration management tool
  ```bash
  curl -sSL https://raw.githubusercontent.com/alehatsman/mooncake/main/install.sh | bash
  ```
- **macOS**: Homebrew (optional, for package management)
- **Linux**: apt/dnf package manager

## Quick Start

```bash
# Clone the repository
git clone https://github.com/alehatsman/dotfiles.git
cd dotfiles

# Create preset symlink (required for presets to work)
ln -s /path/to/mooncake/presets ./presets

# Preview changes (dry-run)
make plan

# Install dotfiles
make install
```

## Installation

### First-Time Setup

1. **Clone and navigate to dotfiles:**
   ```bash
   git clone https://github.com/alehatsman/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Install mooncake** (if not already installed):
   ```bash
   curl -sSL https://raw.githubusercontent.com/alehatsman/mooncake/main/install.sh | bash
   ```

3. **Create preset symlink:**
   ```bash
   # Adjust path to your mooncake installation
   ln -s /Users/alehatsman/Projects/mooncake/presets ./presets
   ```

4. **Create personal variables file** (if needed):
   ```bash
   cp personal_variables.yml my_variables.yml
   # Edit my_variables.yml with your settings
   ```

5. **Preview changes:**
   ```bash
   make plan
   ```

6. **Install:**
   ```bash
   make install
   ```

### Using with Sudo

If some operations require sudo (e.g., changing default shell):

```bash
# Store sudo password (not recommended for shared systems)
echo "your-password" > .sudo

# Or run with sudo access
sudo make install
```

## Available Commands

```bash
make help         # Show available targets
make plan         # Preview changes (dry-run)
make install      # Install dotfiles (personal config)
make install-work # Install with work config
make backup       # Backup current configs
make test-ubuntu  # Test in Ubuntu Docker container
```

## Configuration

### Variables

Configuration is customized through variable files:

**`personal_variables.yml`** - Personal machine settings:
```yaml
FULLNAME: "Your Name"
EMAIL: your.email@example.com
GOPATH: "~/Projects/go-workspace"
OS_USERNAME: yourusername
use_win32yank: false
```

**`work_variables.yml`** - Work machine settings (optional):
```yaml
FULLNAME: "Your Name"
EMAIL: work.email@company.com
GOPATH: "~/work/go"
OS_USERNAME: workusername
use_win32yank: true
```

### Installed Components

The dotfiles install and configure:

#### Programming Languages (Presets)
- **Python 3.12.12** via pyenv with virtualenv support
- **Rust** stable toolchain via rustup
- **Node.js** LTS via nvm (includes webpack, eslint, prettier)
- **Go** latest version with GOPATH configuration

#### Development Tools (Custom)
- **Java** (Ubuntu only)
- **Clojure** with Leiningen
- **Git** with custom configuration
- **Neovim** with Packer plugin manager, LSP, and custom config

#### Terminal Environment
- **Zsh** with oh-my-zsh and zplug
- **Tmux** with TPM (tmux plugin manager)
- **fzf** fuzzy finder

#### macOS Specific
- **Alacritty** terminal emulator
- **macOS** system preferences and defaults

## Project Structure

```
.
├── main.yml                  # Main configuration file
├── personal_variables.yml    # Personal settings
├── work_variables.yml        # Work settings
├── Makefile                  # Common operations
│
├── git/                      # Git configuration
├── zsh/                      # Zsh shell configuration
├── tmux/                     # Tmux configuration
├── nvim/                     # Neovim configuration
├── fzf/                      # fzf fuzzy finder
├── alacritty/               # Alacritty terminal (macOS)
├── macos/                   # macOS system settings
│
├── java/                    # Java setup (Ubuntu)
├── clojure/                 # Clojure setup
│
├── packages/                # System packages
├── presets/                 # Symlink to mooncake presets
└── old/                     # Deprecated configs
```

## Using Mooncake Presets

The dotfiles use mooncake presets for language installations. Presets provide:
- Cross-platform installation
- Version management
- Better error handling
- Standardized configuration

### Example: Python Preset

```yaml
- name: Install Python via pyenv
  preset: python
  with:
    version: "3.12.12"
    install_virtualenv: true
  tags: [dev, python]
```

### Example: Go Preset

```yaml
- name: Install Go toolchain
  preset: go
  with:
    version: "latest"
    gopath: "{{ GOPATH }}"
  tags: [dev, golang]
```

## Selective Installation

Use tags to install specific components:

```bash
# Install only Python
mooncake run -c main.yml -v personal_variables.yml --tags python

# Install only shell tools
mooncake run -c main.yml -v personal_variables.yml --tags core,shell

# Install development languages
mooncake run -c main.yml -v personal_variables.yml --tags dev

# Install macOS specific configs
mooncake run -c main.yml -v personal_variables.yml --tags macos
```

## Common Operations

### Update Language Versions

Edit `main.yml` and change the version:

```yaml
- name: Install Python via pyenv
  preset: python
  with:
    version: "3.12.12"  # Change this
```

Then run `make install` or with specific tag:
```bash
mooncake run -c main.yml -v personal_variables.yml --tags python
```

### Add New Tools

1. Edit `main.yml`
2. Add a new step or preset
3. Run `make plan` to preview
4. Run `make install` to apply

### Backup Current Configs

```bash
make backup
# Configs backed up to ~/.dotfiles-backup/<timestamp>/
```

### Test Before Installing

```bash
# Preview all changes
make plan

# Test in Docker (Ubuntu)
make test-ubuntu
```

## Troubleshooting

### Preset Not Found

If you see "preset not found" errors:
```bash
# Ensure preset symlink exists
ls -la presets/

# Create symlink if missing
ln -s /path/to/mooncake/presets ./presets
```

### Sudo Password Required

Some operations (changing default shell) require sudo:
```bash
# Option 1: Run with sudo
sudo make install

# Option 2: Store password in .sudo file (not recommended for shared systems)
echo "your-password" > .sudo
make install
```

### SSH Key Issues

If git push fails with "Permission denied (publickey)":
```bash
# Option 1: Use HTTPS
git remote set-url origin https://github.com/alehatsman/dotfiles.git

# Option 2: Add SSH key
ssh-add ~/.ssh/id_ed25519
```

## Contributing

This is a personal dotfiles repository, but feel free to:
- Fork and adapt for your own use
- Submit issues if you find bugs
- Share improvements via pull requests

## License

MIT License - See [LICENSE](LICENSE) file

## Acknowledgments

- Built with [mooncake](https://github.com/alehatsman/mooncake)
- Inspired by the dotfiles community

---

**Note**: These dotfiles are personalized for my workflow. Review and customize before using on your system.
