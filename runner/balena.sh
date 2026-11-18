# shellcheck shell=bash
# balenaCloud API calls, used on balena devices (BALENA_DEVICE_UUID is set).
# Sourced by ./start. A failing call only logs a warning: the stack itself does
# not depend on them.

BALENA_API=https://api.balena-cloud.com/v6

balena_api() { # balena_api METHOD PATH [JSON_BODY]
    local args=(-fsS -X "$1" "${BALENA_API}/$2"
        -H "Content-Type: application/json" -H "Authorization: Bearer ${BALENA_API_KEY:-}")
    [[ $# -ge 3 ]] && args+=(--data "$3")
    curl "${args[@]}"
}

BALENA_DEVICE_DATA=$(balena_api GET "device?\$filter=uuid%20eq%20'${BALENA_DEVICE_UUID}'") || {
    warn "Could not read this device from the balenaCloud API"
    BALENA_DEVICE_DATA='{}'
}
BALENA_ID=$(jq -r '.d[0].id // empty' <<< "${BALENA_DEVICE_DATA}" 2> /dev/null) || true

# The device's IP addresses, comma-separated.
balena_get_lan_ip() {
    jq -r '.d[0].ip_address // empty' <<< "${BALENA_DEVICE_DATA}" 2> /dev/null | tr ' ' ',' || true
}

# The bodies are built with jq, so that values such as a PEM certificate, with
# its line breaks, arrive intact.
balena_set_variable() { # balena_set_variable NAME VALUE
    local id
    id=$(balena_api GET "device_environment_variable" \
        | jq -r --arg name "$1" '.d[] | select(.name == $name) | .id' 2> /dev/null) || true
    if [[ -z "${id}" ]]; then
        balena_api POST "device_environment_variable" \
            "$(jq -n --arg device "${BALENA_ID}" --arg name "$1" --arg value "$2" \
                '{device: ($device | tonumber), name: $name, value: $value}')" > /dev/null
    else
        balena_api PATCH "device_environment_variable(${id})" \
            "$(jq -n --arg value "$2" '{value: $value}')" > /dev/null
    fi || warn "Could not set the balena variable $1"
}

balena_set_label() { # balena_set_label NAME VALUE
    local id
    id=$(balena_api GET "device_tag" \
        | jq -r --arg name "$1" '.d[] | select(.tag_key == $name) | .id' 2> /dev/null) || true
    if [[ -z "${id}" ]]; then
        balena_api POST "device_tag" \
            "$(jq -n --arg device "${BALENA_ID}" --arg name "$1" --arg value "$2" \
                '{device: ($device | tonumber), tag_key: $name, value: $value}')" > /dev/null
    else
        balena_api PATCH "device_tag(${id})" \
            "$(jq -n --arg value "$2" '{value: $value}')" > /dev/null
    fi || warn "Could not set the balena label $1"
}
