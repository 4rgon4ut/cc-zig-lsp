#!/bin/bash
# Auto-install ZLS matching project or global Zig version
set -e

ZLS_BASE_DIR="${HOME}/.local/share/zls"
ZLS_BIN_DIR="${HOME}/.local/bin"

# ANSI color codes (disabled if not a terminal)
if [[ -t 2 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED=''
    YELLOW=''
    BOLD=''
    RESET=''
fi

# ZLS releases are signed with minisign. This public key is taken from the
# official install docs (https://zigtools.org/zls/install/) and pinned here on
# purpose: verifying against a key fetched at runtime from the same source as
# the binary would provide no real protection. A compromised release or CDN
# cannot produce an archive that verifies against this key without ZLS's
# private key.
ZLS_MINISIGN_PUBKEY="RWR+9B91GBZ0zOjh6Lr17+zKf5BoSuFvrx2xSeDE57uIYvnKBGmMjOex"

# ─────────────────────────────────────────────────────────────
# Detect Zig version (project-aware)
# Priority: build.zig.zon → .zigversion → global zig
# ─────────────────────────────────────────────────────────────
detect_zig_version() {
    # 1. Check build.zig.zon for minimum_zig_version (official Zig way)
    if [[ -f "build.zig.zon" ]]; then
        local ver
        ver=$(grep -oE '\.minimum_zig_version\s*=\s*"[^"]+"' build.zig.zon 2>/dev/null | \
              sed -E 's/.*"([^"]+)".*/\1/' | head -1)
        if [[ -n "${ver}" ]]; then
            echo "${ver}"
            return 0
        fi
    fi

    # 2. Check .zigversion file (version managers: zv, zvm, zigup)
    if [[ -f ".zigversion" ]]; then
        local ver
        ver=$(tr -d '[:space:]' < .zigversion)
        # Handle special values
        case "${ver}" in
            master|latest|stable)
                # Fetch latest release for these
                ver=$(curl -sL "https://api.github.com/repos/ziglang/zig/releases/latest" | \
                      grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
                ;;
        esac
        if [[ -n "${ver}" ]]; then
            echo "${ver}"
            return 0
        fi
    fi

    # 3. Fall back to global zig version
    if command -v zig &>/dev/null; then
        zig version
        return 0
    fi

    return 1
}

# ─────────────────────────────────────────────────────────────
# Get ZLS binary path for a specific version
# ─────────────────────────────────────────────────────────────
get_zls_path() {
    local version="$1"
    echo "${ZLS_BASE_DIR}/${version}/zls"
}

# ─────────────────────────────────────────────────────────────
# Check if ZLS version is installed
# ─────────────────────────────────────────────────────────────
is_zls_installed() {
    local version="$1"
    local zls_path
    zls_path=$(get_zls_path "${version}")
    [[ -x "${zls_path}" ]]
}

# ─────────────────────────────────────────────────────────────
# Verify a downloaded archive against its minisign signature.
#
# Returns 0 when the signature verifies OR when verification has to be
# skipped (minisign tool absent, or no signature published for the release);
# returns 1 only when a signature IS present but FAILS to verify, which is
# treated as tampering. The skip cases warn loudly so the user is never under
# the illusion that an unverified download was checked.
# ─────────────────────────────────────────────────────────────
verify_signature() {
    local archive="$1"
    local sig="$2"

    if ! command -v minisign &>/dev/null; then
        echo -e "${YELLOW}${BOLD}[WARNING] minisign not found - cannot verify download${RESET}" >&2
        echo -e "${YELLOW}  Install it to enable signature verification:${RESET}" >&2
        echo -e "${YELLOW}    macOS: brew install minisign${RESET}" >&2
        echo -e "${YELLOW}    Linux: apt install minisign (or your package manager)${RESET}" >&2
        echo -e "${YELLOW}  Proceeding WITHOUT verification.${RESET}" >&2
        return 0
    fi

    if [[ ! -f "${sig}" ]]; then
        echo -e "${YELLOW}[WARNING] No signature published for this release - skipping verification${RESET}" >&2
        return 0
    fi

    if minisign -Vm "${archive}" -x "${sig}" -P "${ZLS_MINISIGN_PUBKEY}" >/dev/null 2>&1; then
        echo "Signature verified (minisign)"
        return 0
    fi

    echo -e "${RED}${BOLD}[SECURITY] SIGNATURE VERIFICATION FAILED${RESET}" >&2
    echo -e "${RED}  ${archive##*/} does not match its minisign signature.${RESET}" >&2
    echo -e "${RED}  File may be corrupted or tampered with.${RESET}" >&2
    return 1
}

# ─────────────────────────────────────────────────────────────
# Find latest compatible ZLS version for a given Zig major.minor
# ─────────────────────────────────────────────────────────────
find_compatible_zls() {
    local zig_version="$1"
    local major_minor
    major_minor=$(echo "${zig_version}" | grep -oE '^[0-9]+\.[0-9]+')

    # First check if exact version exists
    if curl -sIf "https://github.com/zigtools/zls/releases/tag/${zig_version}" &>/dev/null; then
        echo "${zig_version}"
        return 0
    fi

    # Find highest ZLS release matching major.minor
    local compatible
    compatible=$(curl -sL "https://api.github.com/repos/zigtools/zls/releases" | \
        grep -oE '"tag_name":\s*"[0-9]+\.[0-9]+\.[0-9]+"' | \
        sed -E 's/.*"([^"]+)".*/\1/' | \
        grep "^${major_minor}\." | \
        sort -V | tail -1)

    if [[ -n "${compatible}" ]]; then
        echo "${compatible}"
        return 0
    fi

    # Fallback to latest release
    curl -sL "https://api.github.com/repos/zigtools/zls/releases/latest" | \
        grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

# ─────────────────────────────────────────────────────────────
# Download and install ZLS for a specific version
# ─────────────────────────────────────────────────────────────
install_zls() {
    local version="$1"

    # Detect platform
    local os arch platform
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)

    case "${os}" in
        darwin) platform="macos" ;;
        linux)  platform="linux" ;;
        *)
            echo "Error: Unsupported OS: ${os}"
            return 1
            ;;
    esac

    case "${arch}" in
        x86_64|amd64)  arch="x86_64" ;;
        arm64|aarch64) arch="aarch64" ;;
        *)
            echo "Error: Unsupported architecture: ${arch}"
            return 1
            ;;
    esac

    local archive_name="zls-${arch}-${platform}.tar.xz"
    local sig_name="${archive_name}.minisig"
    local base_url="https://github.com/zigtools/zls/releases/download/${version}"
    local download_url="${base_url}/${archive_name}"
    local sig_url="${base_url}/${sig_name}"
    local install_dir="${ZLS_BASE_DIR}/${version}"

    echo "Downloading ZLS ${version} for ${platform}-${arch}..."

    mkdir -p "${install_dir}"

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "${temp_dir}"' RETURN

    # Download archive
    if ! curl -fsSL "${download_url}" -o "${temp_dir}/${archive_name}"; then
        echo "Download failed for ZLS ${version}"
        rmdir "${install_dir}" 2>/dev/null || true
        return 1
    fi

    # Download the minisign signature (best-effort) and verify the archive.
    # A failed verification means the bytes don't match ZLS's signature, so we
    # refuse to install rather than run a possibly-tampered binary.
    curl -fsSL "${sig_url}" -o "${temp_dir}/${sig_name}" 2>/dev/null || true
    if ! verify_signature "${temp_dir}/${archive_name}" "${temp_dir}/${sig_name}"; then
        echo -e "${RED}${BOLD}[SECURITY] REFUSING TO INSTALL - SIGNATURE MISMATCH${RESET}" >&2
        echo -e "${RED}Download may have been intercepted or corrupted.${RESET}" >&2
        echo -e "${RED}If this persists, verify your network connection and try again.${RESET}" >&2
        rmdir "${install_dir}" 2>/dev/null || true
        return 1
    fi

    # Extract and install
    tar -xf "${temp_dir}/${archive_name}" -C "${temp_dir}"
    mv "${temp_dir}/zls" "${install_dir}/zls"
    chmod +x "${install_dir}/zls"
    echo "ZLS ${version} installed to ${install_dir}"
    return 0
}

# ─────────────────────────────────────────────────────────────
# Update symlink to active ZLS version
# ─────────────────────────────────────────────────────────────
activate_zls() {
    local version="$1"
    local zls_path
    zls_path=$(get_zls_path "${version}")

    mkdir -p "${ZLS_BIN_DIR}"
    ln -sf "${zls_path}" "${ZLS_BIN_DIR}/zls"
    echo "Activated ZLS ${version} → ${ZLS_BIN_DIR}/zls"
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
main() {
    echo "Checking ZLS installation..."

    # Detect required version
    local zig_version
    if ! zig_version=$(detect_zig_version); then
        echo "Error: Cannot detect Zig version."
        echo "Install Zig first: https://ziglang.org/download/"
        exit 1
    fi

    echo "Detected Zig version: ${zig_version}"

    # Handle dev versions - use latest stable ZLS
    local zls_version
    if [[ "${zig_version}" == *"dev"* ]]; then
        echo "Dev version detected, fetching latest stable ZLS..."
        zls_version=$(curl -sL "https://api.github.com/repos/zigtools/zls/releases/latest" | \
                      grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        # Find compatible ZLS version (may differ from exact Zig version)
        zls_version=$(find_compatible_zls "${zig_version}")
    fi

    if [[ -z "${zls_version}" ]]; then
        echo "Error: Could not determine compatible ZLS version"
        exit 1
    fi

    if [[ "${zls_version}" != "${zig_version}" ]]; then
        echo "Using ZLS ${zls_version} (compatible with Zig ${zig_version})"
    else
        echo "Using ZLS ${zls_version}"
    fi

    # Check if this version is already installed
    if is_zls_installed "${zls_version}"; then
        echo "ZLS ${zls_version} already installed"
        activate_zls "${zls_version}"
        exit 0
    fi

    # Install the required version
    echo "ZLS ${zls_version} not found. Installing..."
    if install_zls "${zls_version}"; then
        activate_zls "${zls_version}"
        echo ""
        echo "Ensure ${ZLS_BIN_DIR} is in your PATH"
        exit 0
    else
        echo ""
        echo "Auto-install failed. Manual options:"
        echo "  - Build from source: https://github.com/zigtools/zls#from-source"
        echo "  - macOS: brew install zls"
        echo "  - Arch:  pacman -S zls"
        exit 1
    fi
}

main "$@"
