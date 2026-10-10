#!/usr/bin/env bash

set -euo pipefail

# CMake installation configuration
CMAKE_BASE="/opt"
CMAKE_LINK="${CMAKE_BASE}/cmake"
CMAKE_BIN="/usr/local/bin"

VERSION=""
ARCH=""
FILE=""
URL=""
INSTALL_DIR=""
TMP_DIR=""

usage()
{
    cat <<EOF
Usage: $0 [options]

Install or update CMake to the latest official release.

Options:
    -v, --version    Show the currently installed CMake version
    -h, --help       Show this help

Without options, install/update the latest CMake version.
EOF
}

get_arch()
{
    case "$(uname -m)" in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            echo "ERROR: unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

get_latest_version()
{
    local tag

    tag=$(curl -fsSL \
        "https://api.github.com/repos/Kitware/CMake/releases/latest" |
        grep '"tag_name":' |
        head -1 |
        sed -E 's/.*"v([^"]+)".*/\1/')

    if [[ -z "${tag}" ]]; then
        echo "ERROR: unable to determine latest CMake version." >&2
        exit 1
    fi

    VERSION="${tag}"
}

show_version()
{
    if command -v cmake >/dev/null 2>&1; then
        cmake --version
    else
        echo "CMake is not installed."
        exit 1
    fi
}

cleanup()
{
    if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}

cleanup_old_versions()
{
    local current
    local dir

    current=$(readlink -f "${CMAKE_LINK}")

    echo
    echo "Checking old CMake installations..."

    for dir in "${CMAKE_BASE}"/cmake-*; do
        [[ -d "${dir}" ]] || continue

        if [[ "$(readlink -f "${dir}")" == "${current}" ]]; then
            continue
        fi

        echo "Removing old installation: ${dir}"
        sudo rm -rf "${dir}"
    done
}

install_cmake()
{
    get_arch
    get_latest_version

    FILE="cmake-${VERSION}-linux-${ARCH}.sh"
    URL="https://github.com/Kitware/CMake/releases/download/v${VERSION}/${FILE}"
    INSTALL_DIR="${CMAKE_BASE}/cmake-${VERSION}"

    echo "CMake version : ${VERSION}"
    echo "Architecture  : ${ARCH}"
    echo "Installer     : ${FILE}"
    echo "Install dir   : ${INSTALL_DIR}"
    echo

    # Already installed?
    if [[ -x "${INSTALL_DIR}/bin/cmake" ]]; then
        echo "CMake ${VERSION} is already installed."

        if [[ -L "${CMAKE_LINK}" ]] &&
           [[ "$(readlink -f "${CMAKE_LINK}")" == "$(readlink -f "${INSTALL_DIR}")" ]]; then
            echo "It is already the active version."
            exit 0
        fi

        echo "Activating existing installation..."
    elif [[ -e "${INSTALL_DIR}" ]]; then
        echo "Removing incomplete installation: ${INSTALL_DIR}"
        sudo rm -rf "${INSTALL_DIR}"
    fi

    # Create temporary directory before installing the EXIT trap.
    TMP_DIR=$(mktemp -d)
    trap cleanup EXIT

    echo "Downloading CMake..."
    curl -fL --progress-bar \
        -o "${TMP_DIR}/${FILE}" \
        "${URL}"

    chmod +x "${TMP_DIR}/${FILE}"

    # The official CMake .sh installer expects the prefix directory to exist.
    echo "Preparing installation directory..."
    sudo mkdir -p "${INSTALL_DIR}"

    echo "Installing CMake..."
    sudo "${TMP_DIR}/${FILE}" \
        --prefix="${INSTALL_DIR}" \
        --skip-license

    # Verify installation before changing the active symlinks.
    if [[ ! -x "${INSTALL_DIR}/bin/cmake" ]]; then
        echo "ERROR: CMake installation failed." >&2
        sudo rm -rf "${INSTALL_DIR}"
        exit 1
    fi

    echo "Updating ${CMAKE_LINK}..."
    sudo ln -sfn \
        "${INSTALL_DIR}" \
        "${CMAKE_LINK}"

    echo "Updating ${CMAKE_BIN}..."
    sudo mkdir -p "${CMAKE_BIN}"

    for program in cmake ctest cpack; do
        if [[ -x "${CMAKE_LINK}/bin/${program}" ]]; then
            sudo ln -sfn \
                "${CMAKE_LINK}/bin/${program}" \
                "${CMAKE_BIN}/${program}"
        fi
    done

    echo
    echo "CMake ${VERSION} installed successfully."
    echo

    "${CMAKE_BIN}/cmake" --version

    cleanup_old_versions
}

main()
{
    case "${1:-}" in
        -v|--version)
            show_version
            ;;
        -h|--help)
            usage
            ;;
        "")
            install_cmake
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
}

main "$@"
