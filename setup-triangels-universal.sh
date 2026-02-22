#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# TriAngels Universal Terminal Setup (Release-grade)
# - Safe defaults (set -euo pipefail)
# - Dependency checks (curl)
# - curl install via package manager (Linux) with sudo
# - Starship install:
#     - macOS: brew (optionally auto-install with TRIANGELS_AUTO_BREW=1)
#     - Linux: official script to ~/.local/bin (no root required)
# - Backups (starship.toml + rc files)
# - Marker blocks in rc files for clean updates/removal
# - Clear output + immediate "apply" command
# ============================================================

APP_NAME="TriAngels Universal Terminal Setup"
APP_VERSION="v1.1.1"
MARK_BEGIN="# >>> TRIANGELS_TERMINAL_STANDARD >>>"
MARK_END="# <<< TRIANGELS_TERMINAL_STANDARD <<<"

STARSHIP_TOML="${HOME}/.config/starship.toml"
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"

OS_TYPE="$(uname -s || true)"
USER_NAME="$(id -un 2>/dev/null || whoami)"
IS_ROOT=false
[[ "${EUID:-$(id -u)}" -eq 0 ]] && IS_ROOT=true
IS_SSH=false
[[ -n "${SSH_CONNECTION:-}" ]] && IS_SSH=true

# Prefer user-local bin for Linux installs (no root).
STARSHIP_BIN_DIR_DEFAULT="${HOME}/.local/bin"

# --------------- helpers ---------------

log()   { printf "%s\n" "$*"; }
info()  { printf "ℹ️  %s\n" "$*"; }
ok()    { printf "✅ %s\n" "$*"; }
warn()  { printf "⚠️  %s\n" "$*"; }
err()   { printf "❌ %s\n" "$*" >&2; }
die()   { err "$*"; exit 1; }

have()  { command -v "$1" >/dev/null 2>&1; }

timestamp() { date +"%Y%m%d-%H%M%S"; }

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    local b="${f}.bak.$(timestamp)"
    cp -a "$f" "$b"
    ok "Backup created: $b"
  fi
}

ensure_file_exists() {
  local f="$1"
  local d
  d="$(dirname "$f")"
  mkdir -p "$d"
  if [[ ! -f "$f" ]]; then
    : > "$f"
    ok "Created: $f"
  fi
}

ensure_newline_eof() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  # If file is empty -> add newline after writes naturally; do nothing here.
  if [[ -s "$f" ]]; then
    # Read last byte safely
    local last
    last="$(tail -c 1 "$f" 2>/dev/null || true)"
    [[ "$last" == $'\n' ]] || printf "\n" >> "$f"
  fi
}

need_sudo_prefix() {
  # Echo "sudo" if not root and sudo exists, else empty.
  if [[ "$IS_ROOT" == true ]]; then
    echo ""
    return 0
  fi
  if have sudo; then
    echo "sudo"
    return 0
  fi
  echo ""
}

detect_shell() {
  local s=""
  if [[ -n "${SHELL:-}" ]]; then
    s="$(basename "${SHELL}")"
  fi
  # fallback
  if [[ -z "$s" ]]; then
    s="$(ps -p $$ -o comm= 2>/dev/null | awk '{print $1}' | xargs basename || true)"
  fi
  case "$s" in
    zsh|bash) echo "$s" ;;
    *) echo "zsh" ;; # macOS default; safe fallback
  esac
}

# Remove the TRIANGELS marker block from a file (idempotent)
remove_marker_block() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if grep -qF "$MARK_BEGIN" "$f" 2>/dev/null; then
    backup_file "$f"
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {inblock=1; next}
      $0==e {inblock=0; next}
      inblock!=1 {print}
    ' "$f" > "${f}.tmp"
    mv "${f}.tmp" "$f"
    ok "Removed old TriAngels block from: $f"
  fi
}

# Append TRIANGELS block to a file (idempotent + replace old)
ensure_marker_block() {
  local f="$1"
  local shell="$2"   # bash|zsh
  local bin_dir="$3" # optional extra bin path (Linux ~/.local/bin)
  ensure_file_exists "$f"

  remove_marker_block "$f"
  ensure_newline_eof "$f"

  {
    printf "%s\n" "$MARK_BEGIN"
    printf "# %s %s\n" "$APP_NAME" "$APP_VERSION"
    printf "# Added on: %s\n" "$(date)"
    if [[ -n "$bin_dir" ]]; then
      printf "# Ensure Starship is in PATH\n"
      printf 'export PATH="%s:$PATH"\n' "$bin_dir"
    fi
    printf 'eval "$(starship init %s)"\n' "$shell"
    printf "%s\n" "$MARK_END"
  } >> "$f"

  ok "Installed TriAngels block into: $f"
}

detect_pkg_manager() {
  for pm in apt-get dnf yum pacman apk zypper; do
    if have "$pm"; then
      echo "$pm"
      return 0
    fi
  done
  echo ""
}

install_curl_linux() {
  local pm sudo_prefix
  pm="$(detect_pkg_manager)"
  [[ -n "$pm" ]] || die "curl is missing and no supported package manager was detected. Install curl manually."

  sudo_prefix="$(need_sudo_prefix)"
  [[ -n "$sudo_prefix" || "$IS_ROOT" == true ]] || die "Need root/sudo to install curl. Install curl manually or run as root."

  info "curl not found. Installing via package manager: $pm"
  case "$pm" in
    apt-get)
      $sudo_prefix apt-get update -y
      $sudo_prefix apt-get install -y curl ca-certificates
      ;;
    dnf)
      $sudo_prefix dnf install -y curl ca-certificates
      ;;
    yum)
      $sudo_prefix yum install -y curl ca-certificates
      ;;
    pacman)
      $sudo_prefix pacman -Sy --noconfirm curl ca-certificates
      ;;
    apk)
      $sudo_prefix apk add --no-cache curl ca-certificates
      ;;
    zypper)
      $sudo_prefix zypper --non-interactive install curl ca-certificates
      ;;
    *)
      die "Unsupported package manager: $pm. Install curl manually."
      ;;
  esac

  have curl || die "curl install attempted but curl still not available."
  ok "curl installed."
}

install_homebrew_mac() {
  # Optional auto-install for wow-experience.
  # Will require sudo + ENTER; still “one command”, but interactive.
  info "Homebrew not found. Installing Homebrew (interactive; may ask password / press ENTER)."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Ensure brew available in current session (Apple Silicon default path)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  have brew || die "Homebrew install finished but brew not found. Open new terminal and re-run."
  ok "Homebrew installed."
}

install_starship() {
  if have starship; then
    ok "Starship already installed."
    return 0
  fi

  info "Starship not found. Installing..."

  if [[ "$OS_TYPE" == "Darwin" ]]; then
    if ! have brew; then
      if [[ "${TRIANGELS_AUTO_BREW:-0}" == "1" ]]; then
        install_homebrew_mac
      else
        die "Homebrew not found. Install Homebrew, then re-run. (Or run with TRIANGELS_AUTO_BREW=1 to auto-install.)"
      fi
    fi

    brew install starship
    have starship || die "Starship install via brew failed."
    ok "Starship installed via Homebrew."
    return 0
  fi

  # Linux install via official script into ~/.local/bin (no root)
  have curl || install_curl_linux
  mkdir -p "$STARSHIP_BIN_DIR_DEFAULT"

  info "Installing Starship via official installer script into: $STARSHIP_BIN_DIR_DEFAULT"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$STARSHIP_BIN_DIR_DEFAULT"

  # Ensure current process can see it
  export PATH="$STARSHIP_BIN_DIR_DEFAULT:$PATH"
  have starship || die "Starship installer finished but starship not found in PATH."
  ok "Starship installed."
}

generate_starship_config() {
  mkdir -p "${HOME}/.config"

  if [[ -f "$STARSHIP_TOML" ]]; then
    backup_file "$STARSHIP_TOML"
  fi

  local host_color="green"
  [[ "$OS_TYPE" == "Darwin" ]] && host_color="blue"

  local user_color="bold cyan"
  [[ "$IS_ROOT" == true ]] && user_color="bold red"

  cat > "$STARSHIP_TOML" <<EOF
# ====================================
# TriAngels Universal Profile ($APP_VERSION)
# ====================================

[os]
disabled = false
style = "bold white"

[username]
show_always = true
style_user = "$user_color"
style_root = "bold red"
format = "[\$user](\$style) "

[hostname]
ssh_only = false
style = "bold $host_color"
format = "🖥 [\$hostname](\$style) "

[localip]
disabled = false
ssh_only = false
format = "🌍 [\$localipv4](\$style) "
style = "bright-white"

[directory]
style = "bright-white"

[docker_context]
symbol = "🐳 "
style = "bold yellow"
format = "via [\$symbol\$context](\$style) "

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"
EOF

  ok "Starship config written: $STARSHIP_TOML"
}

attach_to_shells() {
  local current_shell
  current_shell="$(detect_shell)"

  # Always create + attach to CURRENT shell rc for wow-effect
  case "$current_shell" in
    zsh)
      ensure_marker_block "$ZSHRC" "zsh" ""
      ;;
    bash)
      ensure_marker_block "$BASHRC" "bash" ""
      ;;
  esac

  # Also attach to the other shell if it exists (nice-to-have)
  if [[ "$current_shell" != "bash" && -f "$BASHRC" ]]; then
    ensure_marker_block "$BASHRC" "bash" ""
  fi
  if [[ "$current_shell" != "zsh" && -f "$ZSHRC" ]]; then
    ensure_marker_block "$ZSHRC" "zsh" ""
  fi

  # On Linux we installed to ~/.local/bin: make sure that shell gets PATH fix
  if [[ "$OS_TYPE" != "Darwin" ]]; then
    # Re-apply with bin dir for both files that exist / were created
    if [[ "$current_shell" == "zsh" ]]; then
      remove_marker_block "$ZSHRC"
      ensure_marker_block "$ZSHRC" "zsh" "$STARSHIP_BIN_DIR_DEFAULT"
    else
      remove_marker_block "$BASHRC"
      ensure_marker_block "$BASHRC" "bash" "$STARSHIP_BIN_DIR_DEFAULT"
    fi
  fi
}

print_summary() {
  local current_shell apply_cmd
  current_shell="$(detect_shell)"
  apply_cmd="source ~/.${current_shell}rc"

  log ""
  log "======================================"
  log "  ${APP_NAME} ${APP_VERSION}"
  log "======================================"
  info "Detected OS: $OS_TYPE"
  info "User: $USER_NAME (root=$IS_ROOT)"
  info "SSH session: $IS_SSH"
  log ""
  ok "Done."

  log ""
  log "✅ Apply now (copy one line):"
  log "  ${apply_cmd}"
  log ""
  log "Config files:"
  log "  • Starship config: $STARSHIP_TOML"
  log ""
  log "Uninstall / rollback:"
  log "  • Remove TriAngels block from rc files:"
  log "      awk -v b='$MARK_BEGIN' -v e='$MARK_END' '\$0==b{in=1;next} \$0==e{in=0;next} !in{print}' ~/.bashrc > ~/.bashrc.tmp 2>/dev/null && mv ~/.bashrc.tmp ~/.bashrc || true"
  log "      awk -v b='$MARK_BEGIN' -v e='$MARK_END' '\$0==b{in=1;next} \$0==e{in=0;next} !in{print}' ~/.zshrc  > ~/.zshrc.tmp  2>/dev/null && mv ~/.zshrc.tmp  ~/.zshrc  || true"
  log "  • Remove Starship config:"
  log "      rm -f ~/.config/starship.toml"
  log ""
}

auto_apply_and_reload_shell() {
  # ВАЖНО:
  # Скрипт обычно запускают как: curl ... | bash
  # Значит он выполняется в bash, и НЕЛЬЗЯ source ~/.zshrc из bash.

  log ""
  ok "Apply now (copy one line):"

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # Если скрипт реально выполняется в zsh — можно source .zshrc
    echo "source ~/.zshrc"
    [[ -f "$ZSHRC" ]] && source "$ZSHRC" 2>/dev/null || true
    return 0
  fi

  if [[ -n "${BASH_VERSION:-}" ]]; then
    # Скрипт выполняется в bash — source только bashrc
    if [[ -f "$BASHRC" ]]; then
      echo "source ~/.bashrc"
      source "$BASHRC" 2>/dev/null || true
    else
      # bashrc нет — не трогаем zshrc, просто даём правильную команду
      echo "exec \$SHELL -l"
    fi
    return 0
  fi

  # На всякий случай
  echo "exec \$SHELL -l"
}

main() {
  log "======================================"
  log "  ${APP_NAME}"
  log "  ${APP_VERSION}"
  log "======================================"

  install_starship
  generate_starship_config
  attach_to_shells
  print_summary
  auto_apply_and_reload_shell
}

main "$@"
