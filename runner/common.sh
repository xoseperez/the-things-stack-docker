# shellcheck shell=bash
# Helpers for the start script. The same file serves the ChirpStack images.

COLOR_INFO="\e[32m"
COLOR_WARNING="\e[33m"
COLOR_ERROR="\e[31m"
COLOR_RESET="\e[0m"

info() { echo -e "${COLOR_INFO}$*${COLOR_RESET}"; }
warn() { echo -e "${COLOR_WARNING}$*${COLOR_RESET}" >&2; }

# The pause keeps a restart policy from spinning on a bad configuration.
fail() { echo -e "${COLOR_ERROR}ERROR: $*${COLOR_RESET}" >&2; sleep 5; exit 1; }

# Accept a renamed variable under its old name, with a warning.
env_alias() { # env_alias NEW OLD
    if [[ -z "${!1:-}" && -n "${!2:-}" ]]; then
        warn "$2 is deprecated, use $1 instead"
        printf -v "$1" '%s' "${!2}"
    fi
}

# Escape a value that goes inside a TOML "..." string (passwords, paths).
toml_escape() {
    local value=${1//\\/\\\\}
    printf '%s' "${value//\"/\\\"}"
}

# Fill ${VAR} placeholders in a template. Only the listed variables are replaced,
# so any other "$" text in the template is left alone.
render() { # render TEMPLATE OUTPUT VAR...
    local template=$1 output=$2
    shift 2
    # The arguments are variable names: export those variables for envsubst, and
    # hand it the literal list "${A} ${B} ..." of placeholders to replace.
    # shellcheck disable=SC2163
    export "$@"
    # shellcheck disable=SC2016
    envsubst "$(printf '${%s} ' "$@")" < "${template}" > "${output}"
}

# Wait for concentratord-style IPC sockets to appear under /tmp. The pause first
# gives a concentratord that is starting at the same time a moment to replace the
# sockets left over from its previous run.
wait_for_sockets() { # wait_for_sockets NAME...
    sleep 2
    local name
    for name in "$@"; do
        while [[ ! -S "/tmp/${name}_event" ]]; do sleep 1; done
    done
}
