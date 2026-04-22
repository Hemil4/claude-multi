#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# claude-multi installer
# ─────────────────────────────────────────────────────────────────────────────

REPO="Hemil4/claude-multi"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="claude-multi"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { printf "  ${CYAN}>${RESET} %s\n" "$1"; }
success() { printf "  ${GREEN}✔${RESET} %s\n" "$1"; }
warn()    { printf "  ${YELLOW}!${RESET} %s\n" "$1"; }
error()   { printf "  ${RED}✘${RESET} %s\n" "$1"; exit 1; }

# ── Install ──────────────────────────────────────────────────────────────────

install() {
    echo ""
    printf "  ${BOLD}claude-multi${RESET} — installer\n"
    echo ""

    mkdir -p "$INSTALL_DIR"

    info "Downloading claude-multi..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/claude-multi" -o "${INSTALL_DIR}/${BINARY_NAME}"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "${INSTALL_DIR}/${BINARY_NAME}" "https://raw.githubusercontent.com/${REPO}/main/claude-multi"
    else
        error "curl or wget is required."
    fi

    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    success "Installed to ${INSTALL_DIR}/${BINARY_NAME}"

    # Check PATH
    if ! echo "$PATH" | tr ':' '\n' | grep -q "^${INSTALL_DIR}$"; then
        warn "${INSTALL_DIR} is not in your PATH."
        echo ""
        local shell_config="$HOME/.zshrc"
        if [ -n "${BASH_VERSION:-}" ]; then
            shell_config="$HOME/.bashrc"
        fi
        info "Add it:"
        printf "    ${DIM}echo 'export PATH=\"%s:\$PATH\"' >> %s${RESET}\n" "$INSTALL_DIR" "$shell_config"
        printf "    ${DIM}source %s${RESET}\n" "$shell_config"
        echo ""
    fi

    # Check for gum
    if ! command -v gum >/dev/null 2>&1; then
        info "Installing gum (interactive UI)..."
        if command -v brew >/dev/null 2>&1; then
            brew install gum
        else
            warn "gum not found. Install for best experience:"
            printf "    ${DIM}brew install gum${RESET}\n"
        fi
    fi

    # Check for claude
    if ! command -v claude >/dev/null 2>&1; then
        warn "Claude Code not found. Install it first:"
        printf "    ${DIM}https://docs.anthropic.com/en/docs/claude-code${RESET}\n"
    fi

    echo ""
    success "Installation complete!"
    echo ""
    printf "  ${BOLD}Quick start:${RESET}\n"
    printf "    ${CYAN}claude-multi create work${RESET}         ${DIM}# create a profile${RESET}\n"
    printf "    ${CYAN}claude-multi work${RESET}                ${DIM}# launch (first time: /login)${RESET}\n"
    printf "    ${CYAN}claude-multi work -r${RESET}             ${DIM}# resume a session${RESET}\n"
    printf "    ${CYAN}claude-multi${RESET}                     ${DIM}# interactive menu${RESET}\n"
    echo ""
    printf "  ${BOLD}Key feature:${RESET} Sessions auto-shared across all profiles.\n"
    printf "  ${DIM}  Hit your limit? Switch profile, resume the same session.${RESET}\n"
    echo ""
}

# ── Uninstall ────────────────────────────────────────────────────────────────

uninstall() {
    echo ""
    printf "  ${BOLD}claude-multi${RESET} — uninstaller\n"
    echo ""

    if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        rm -f "${INSTALL_DIR}/${BINARY_NAME}"
        success "Removed ${INSTALL_DIR}/${BINARY_NAME}"
    else
        warn "claude-multi not found at ${INSTALL_DIR}/${BINARY_NAME}"
    fi

    echo ""
    info "Profile directories (~/.claude-*) were not removed."
    info "Remove them manually if needed."
    echo ""
}

# ── Entry point ──────────────────────────────────────────────────────────────

case "${1:-}" in
    uninstall|--uninstall) uninstall ;;
    *)                     install ;;
esac
