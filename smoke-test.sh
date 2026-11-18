#!/usr/bin/env bash

# Checks a built image before it is pushed:
# - ttn-lw-stack runs on the platform and is the upstream version the image
#   names;
# - the start script rejects bad settings, and writes a configuration that the
#   stack reads back with every value intact, including ones with quotes,
#   slashes or "&";
# - a full start against PostgreSQL and Redis serves the Console over TLS with
#   the generated certificates, does not store the admin password, and stops
#   promptly on docker stop;
# - a restart keeps the certificates and cookie keys, and renews a server
#   certificate that is about to expire without replacing the CA.
#
#   ./smoke-test.sh IMAGE PLATFORM

set -euo pipefail

IMAGE=$1
PLATFORM=$2

# Under emulation the stack takes much longer to start.
START_TIMEOUT=${START_TIMEOUT:-300}
NAME=smoke-tts-$$
DOMAIN=lns.example.com
POSTGRES_IMAGE=postgres:14-alpine
REDIS_IMAGE=redis:7-alpine

run() { docker run --rm --platform "${PLATFORM}" "$@"; }

fail() { echo "FAIL: $*" >&2; exit 1; }

# expect TEXT LABEL WANTED... : every WANTED string must appear in TEXT.
expect() {
    local text=$1 label=$2 wanted
    shift 2
    for wanted in "$@"; do
        grep -qF -- "${wanted}" <<< "${text}" || fail "'${wanted}' missing from the ${label}"
    done
}

cleanup() {
    docker rm -f "${NAME}-stack" "${NAME}-postgres" "${NAME}-redis" > /dev/null 2>&1 || true
    docker network rm "${NAME}" > /dev/null 2>&1 || true
    docker volume rm "${NAME}-data" > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "== ${PLATFORM}: version"
UPSTREAM=$(docker image inspect "${IMAGE}" \
    --format '{{ index .Config.Labels "org.opencontainers.image.base.name" }}')
UPSTREAM=${UPSTREAM##*:}
VERSIONS=$(run --entrypoint sh "${IMAGE}" -c 'ttn-lw-stack version; ttn-lw-cli version; openssl version')
echo "${VERSIONS}" | grep -E '^(Version|OpenSSL)'
expect "${VERSIONS}" "version output" "Version:             ${UPSTREAM}" "OpenSSL 3"

echo "== ${PLATFORM}: bad settings are rejected"
for SETTING in TTS_DOMAIN= "TTS_DOMAIN=lns.example.com/x" TTS_PORT=0 TTS_NET_ID=13 \
    TTS_DEVADDR_RANGE=00000000 PB_HOME_ENABLE=yes TTS_SUBJECT_COUNTRY=Spain; do
    OUTPUT=$(run -e TTS_DOMAIN="${DOMAIN}" -e "${SETTING}" "${IMAGE}" --render 2>&1) \
        && fail "${SETTING} was accepted"
    expect "${OUTPUT}" "output for ${SETTING}" "ERROR: ${SETTING%%=*}"
done

echo "== ${PLATFORM}: configuration"
# Quotes, slashes, "&" and "$" all broke or changed the configuration when it
# was written with sed.
TRICKY="it's a/b&c\\d \"q\" \$HOME #x"
SETTINGS=(-e TTS_DOMAIN="${DOMAIN}" -e TTS_PORT=8443 -e TTS_SMTP_HOST=smtp.example.com
    -e "TTS_SMTP_PASS=${TRICKY}" -e "TTS_SERVER_NAME=${TRICKY}" -e PB_FORWARDER_ENABLE=true)
CONFIG=$(run "${SETTINGS[@]}" "${IMAGE}" --render)
if grep -vE '^ *#' <<< "${CONFIG}" | grep -nE '\$\{|\{\{'; then
    fail "placeholders left in the configuration"
fi
expect "${CONFIG}" "configuration" "oauth-server-address: https://${DOMAIN}:8443/oauth" \
    "    packetbroker : [" "provider: smtp"
# The stack's own view of the configuration file.
# shellcheck disable=SC2016
PARSED=$(run "${SETTINGS[@]}" --entrypoint bash "${IMAGE}" -c \
    'bash start --render > /dev/null && ttn-lw-stack -c ttn-lw-stack-docker.yml config --env') \
    || fail "the stack could not read the configuration"
expect "${PARSED}" "parsed configuration" \
    "TTN_LW_IS_EMAIL_SMTP_PASSWORD=\"${TRICKY}\"" \
    "TTN_LW_IS_EMAIL_SENDER_NAME=\"${TRICKY}\"" \
    "TTN_LW_CONSOLE_UI_CANONICAL_URL=\"https://${DOMAIN}:8443/console\""

echo "== ${PLATFORM}: full start"
docker network create "${NAME}" > /dev/null
docker run -d --name "${NAME}-postgres" --network "${NAME}" -e POSTGRES_USER=root \
    -e POSTGRES_PASSWORD=root -e POSTGRES_DB=ttn_lorawan "${POSTGRES_IMAGE}" > /dev/null
docker run -d --name "${NAME}-redis" --network "${NAME}" "${REDIS_IMAGE}" > /dev/null
# The database URI has no port, so the start script's default is used.
docker create --name "${NAME}-stack" --platform "${PLATFORM}" --network "${NAME}" \
    -v "${NAME}-data:/srv/data" \
    -e TTS_DOMAIN="${DOMAIN}" \
    -e TTS_ADMIN_PASSWORD=smoke-admin-secret \
    -e TTN_LW_REDIS_ADDRESS="${NAME}-redis:6379" \
    -e TTN_LW_IS_DATABASE_URI="postgres://root:root@${NAME}-postgres/ttn_lorawan?sslmode=disable" \
    "${IMAGE}" > /dev/null

in_stack() { docker exec "${NAME}-stack" "$@"; }

start_stack() {
    docker start "${NAME}-stack" > /dev/null
    local deadline=$(( SECONDS + START_TIMEOUT ))
    until in_stack curl -fsS -o /dev/null http://localhost:1885/healthz 2> /dev/null; do
        if [[ "$(docker inspect -f '{{.State.Running}}' "${NAME}-stack")" != "true" ]] \
            || (( SECONDS > deadline )); then
            docker logs "${NAME}-stack" 2>&1 | tail -n 40
            fail "the stack did not become healthy"
        fi
        sleep 2
    done
    echo "healthy after $(( SECONDS - deadline + START_TIMEOUT ))s"
}

stop_stack() {
    local started=${SECONDS}
    docker stop -t 30 "${NAME}-stack" > /dev/null
    (( SECONDS - started < 10 )) || fail "docker stop took $(( SECONDS - started ))s: the stack ignored SIGTERM"
}

fingerprint() { in_stack sh -c 'cd /srv/data && sha256sum ca.pem ca-key.pem cookie_block_key cookie_hash_key'; }

start_stack
LOGS=$(docker logs "${NAME}-stack" 2>&1)
expect "${LOGS}" "start output" "Creating a certificate authority" "Based on lorawan-stack ${UPSTREAM}"
# The Console over TLS, checked against the generated CA, for the domain and
# for localhost.
in_stack curl -fsS -o /dev/null --cacert /srv/data/ca.pem \
    --resolve "${DOMAIN}:8885:127.0.0.1" "https://${DOMAIN}:8885/console" \
    || fail "the Console is not served over TLS for ${DOMAIN} with the generated CA"
in_stack curl -fsS -o /dev/null --cacert /srv/data/ca.pem "https://localhost:8885/console" \
    || fail "the Console is not served over TLS for localhost with the generated CA"
if in_stack grep -rqF smoke-admin-secret /srv/data; then
    fail "the admin password is stored in the data folder"
fi
BEFORE=$(fingerprint)
stop_stack

echo "== ${PLATFORM}: restart, with a server certificate about to expire"
# Replace the server certificate with one from the same CA that expires
# tomorrow, as if the stack had been running for two years.
run --entrypoint bash -v "${NAME}-data:/srv/data" "${IMAGE}" -c '
    cd /srv/data
    openssl req -new -key key.pem -subj "/CN=old" 2> /dev/null \
        | openssl x509 -req -CA ca.pem -CAkey ca-key.pem -set_serial 1 -days 1 -out cert.pem 2> /dev/null' \
    || fail "could not create the expiring certificate"
start_stack
expect "$(docker logs "${NAME}-stack" 2>&1)" "restart output" "Renewing the server certificate"
[[ "$(fingerprint)" == "${BEFORE}" ]] || fail "the CA or the cookie keys changed on restart"
in_stack openssl x509 -checkend $(( 700 * 24 * 3600 )) -noout -in /srv/data/cert.pem > /dev/null \
    || fail "the server certificate was not renewed"
in_stack curl -fsS -o /dev/null --cacert /srv/data/ca.pem "https://localhost:8885/console" \
    || fail "the renewed certificate is not served"
stop_stack

echo "== ${PLATFORM}: OK"
