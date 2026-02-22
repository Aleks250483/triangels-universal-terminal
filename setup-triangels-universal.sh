#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# TriAngels Universal Terminal Setup (Release-grade)
# - Safe defaults (set -euo pipefail)
# - Dependency checks (curl)
# - Optional curl install via package manager (Linux)
# - Starship install (brew on macOS, official script on Linux)
# - Backups (starship.toml + rc files)
# - Marker blocks in rc files for clean updates/removal
# - Clear output
# ============================================================

APP_NAME="TriAngels Universal Terminal Setup"
APP_VERSION="v1.1.0"
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

# Remove the TRIANGELS marker block from a file (idempotent)
remove_marker_block() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  if grep -qF "$MARK_BEGIN" "$f" 2>/dev/null; then
    backup_file "$f"
    # delete from MARK_BEGIN to MARK_END inclusive
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
  local shell="$2" # bash|zsh
  [[ -f "$f" ]] || return 0

  remove_marker_block "$f"
  # Ensure newline at EOF
  tail -c 1 "$f" | read -r _ || true
  printf "\n%s\n" "$MARK_BEGIN" >> "$f"
  printf "# %s %s\n" "$APP_NAME" "$APP_VERSION" >> "$f"
  printf "# Added on: %s\n" "$(date)" >> "$f"
  printf 'eval "$(starship init %s)"\n' "$shell" >> "$f"
  printf "%s\n" "$MARK_END" >> "$f"
  ok "Installed TriAngels block into: $f"
}

detect_pkg_manager() {
  # returns a command name or empty
  for pm in apt-get dnf yum pacman apk zypper; do
    if have "$pm"; then
      echo "$pm"
      return 0
    fi
  done
  echo ""
}

install_curl_linux() {
  local pm
  pm="$(detect_pkg_manager)"
  [[ -n "$pm" ]] || die "curl is missing and no supported package manager was detected. Install curl manually."

  info "curl not found. Installing via package manager: $pm"
  case "$pm" in
    apt-get)
      $IS_ROOT || die "Need root to install curl via apt-get. Run: sudo $0"
      apt-get update -y
      apt-get install -y curl ca-certificates
      ;;
    dnf)
      $IS_ROOT || die "Need root to install curl via dnf. Run: sudo $0"
      dnf install -y curl ca-certificates
      ;;
    yum)
      $IS_ROOT || die "Need root to install curl via yum. Run: sudo $0"
      yum install -y curl ca-certificates
      ;;
    pacman)
      $IS_ROOT || die "Need root to install curl via pacman. Run: sudo $0"
      pacman -Sy --noconfirm curl ca-certificates
      ;;
    apk)
      $IS_ROOT || die "Need root to install curl via apk. Run: sudo $0"
      apk add --no-cache curl ca-certificates
      ;;
    zypper)
      $IS_ROOT || die "Need root to install curl via zypper. Run: sudo $0"
      zypper --non-interactive install curl ca-certificates
      ;;
    *)
      die "Unsupported package manager: $pm. Install curl manually."
      ;;
  esac

  have curl || die "curl install attempted but curl still not available."
  ok "curl installed."
}

install_starship() {
  if have starship; then
    ok "Starship already installed."
    return 0
  fi

  info "Starship not found. Installing..."

  if [[ "$OS_TYPE" == "Darwin" ]]; then
    have brew || die "Homebrew not found. Install Homebrew, then re-run."
    brew install starship
    have starship || die "Starship install via brew failed."
    ok "Starship installed via Homebrew."
    return 0
  fi

  # Linux install via official script (https://starship.rs)
  have curl || install_curl_linux

  info "Installing Starship via official installer script (non-interactive)."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
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
  $IS_ROOT && user_color="bold red"

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
  local attached_any=false

  if [[ -f "$BASHRC" ]]; then
    ensure_marker_block "$BASHRC" "bash"
    attached_any=true
  else
    warn "~/.bashrc not found. Skipping bash attach."
  fi

  if [[ -f "$ZSHRC" ]]; then
    ensure_marker_block "$ZSHRC" "zsh"
    attached_any=true
  else
    warn "~/.zshrc not found. Skipping zsh attach."
  fi

  if [[ "$attached_any" == false ]]; then
    warn "No rc files found (.bashrc/.zshrc). You must manually add: eval \"\$(starship init <shell>)\""
  fi
}

print_summary() {
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
  log "Next steps:"
  log "  • Restart your terminal, or run:"
  log "      bash:  source ~/.bashrc"
  log "      zsh:   source ~/.zshrc"
  log ""
  log "Config files:"
  log "  • Starship config: $STARSHIP_TOML"
  log ""
  log "Uninstall / rollback:"
  log "  • Remove TriAngels blocks from rc files:"
  log "      sed -i.bak '/TRIANGELS_TERMINAL_STANDARD/,+2d' ~/.bashrc 2>/dev/null || true"
  log "      sed -i.bak '/TRIANGELS_TERMINAL_STANDARD/,+2d' ~/.zshrc 2>/dev/null || true"
  log "    (or restore from the .bak.<timestamp> backups created by this script)"
  log "  • Remove Starship config:"
  log "      rm -f ~/.config/starship.toml"
  log ""
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
}

main "$@"