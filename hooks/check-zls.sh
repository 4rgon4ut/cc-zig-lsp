#!/bin/bash
# Auto-install ZLS matching project or global Zig version
set -e

ZLS_BASE_DIR="${HOME}/.local/share/zls"
ZLS_BIN_DIR="${HOME}/.local/bin"

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
# Verify SHA256 checksum
# ─────────────────────────────────────────────────────────────
verify_checksum() {
    local file="$1"
    local expected_hash="$2"
    local actual_hash

    # Use shasum on macOS, sha256sum on Linux
    if command -v shasum &>/dev/null; then
        actual_hash=$(shasum -a 256 "${file}" | awk '{print $1}')
    elif command -v sha256sum &>/dev/null; then
        actual_hash=$(sha256sum "${file}" | awk '{print $1}')
    else
        echo "Warning: No SHA256 tool found, skipping verification"
        return 0
    fi

    if [[ "${actual_hash}" == "${expected_hash}" ]]; then
        echo "Checksum verified: ${actual_hash:0:16}..."
        return 0
    else
        echo "Checksum FAILED!"
        echo "  Expected: ${expected_hash}"
        echo "  Got:      ${actual_hash}"
        return 1
    fi
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
    local checksum_name="${archive_name}.sha256"
    local base_url="https://github.com/zigtools/zls/releases/download/${version}"
    local download_url="${base_url}/${archive_name}"
    local checksum_url="${base_url}/${checksum_name}"
    local install_dir="${ZLS_BASE_DIR}/${version}"

    echo "Downloading ZLS ${version} for ${platform}-${arch}..."

    mkdir -p "${install_dir}"

    local temp_dir
    temp_dir=$(mktemp -d)
    trap 'rm -rf "${temp_dir}"' RETURN

    # Download archive
    if ! curl -fsSL "${download_url}" -o "${temp_dir}/${archive_name}"; then
        echo "Download failed for ZLS ${version}"
        return 1
    fi

    # Download and verify checksum
    local expected_hash
    if curl -fsSL "${checksum_url}" -o "${temp_dir}/${checksum_name}" 2>/dev/null; then
        expected_hash=$(awk '{print $1}' "${temp_dir}/${checksum_name}")
        if ! verify_checksum "${temp_dir}/${archive_name}" "${expected_hash}"; then
            echo "Security: Refusing to install - checksum mismatch"
            return 1
        fi
    else
        echo "Warning: Checksum file not available, proceeding without verification"
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

    echo "Required Zig/ZLS version: ${zig_version}"

    # Handle dev versions - use latest stable ZLS
    if [[ "${zig_version}" == *"dev"* ]]; then
        echo "Dev version detected, fetching latest stable ZLS..."
        zig_version=$(curl -sL "https://api.github.com/repos/zigtools/zls/releases/latest" | \
                      grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
        echo "Using ZLS version: ${zig_version}"
    fi

    # Check if this version is already installed
    if is_zls_installed "${zig_version}"; then
        echo "ZLS ${zig_version} already installed"
        activate_zls "${zig_version}"
        exit 0
    fi

    # Install the required version
    echo "ZLS ${zig_version} not found. Installing..."
    if install_zls "${zig_version}"; then
        activate_zls "${zig_version}"
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
