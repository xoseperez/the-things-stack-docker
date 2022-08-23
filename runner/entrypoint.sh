#!/bin/sh

replace_placeholders() {
    FILE=$1
    sed -i -e "s/{{server_name}}/${TTS_SERVER_NAME}/g" $FILE
    sed -i -e "s/{{admin_email}}/${TTS_ADMIN_EMAIL}/g" $FILE
    sed -i -e "s/{{noreply_email}}/${TTS_NOREPLY_EMAIL}/g" $FILE
    sed -i -e "s/{{console_secret}}/${TTS_CONSOLE_SECRET}/g" $FILE
    sed -i -e "s/{{domain}}/${TTS_DOMAIN}/g" $FILE
    sed -i -e "s/{{port}}/${TTS_PORT}/g" $FILE
    sed -i -e "s/{{mail_provider}}/${MAIL_PROVIDER}/g" $FILE
    sed -i -e "s/{{sendgrid_key}}/${TTS_SENDGRID_KEY}/g" $FILE
    sed -i -e "s/{{smtp_host}}/${TTS_SMTP_HOST}/g" $FILE
    sed -i -e "s/{{smtp_user}}/${TTS_SMTP_USER}/g" $FILE
    sed -i -e "s/{{smtp_pass}}/${TTS_SMTP_PASS}/g" $FILE
    sed -i -e "s/{{block_key}}/${BLOCK_KEY}/g" $FILE
    sed -i -e "s/{{hash_key}}/${HASH_KEY}/g" $FILE
    sed -i -e "s/{{metrics_password}}/${TTS_METRICS_PASSWORD}/g" $FILE
    sed -i -e "s/{{pprof_password}}/${TTS_PPROF_PASSWORD}/g" $FILE
    sed -i -e "s/{{device_claiming_secret}}/${TTS_DEVICE_CLAIMING_SECRET}/g" $FILE
    sed -i -e "s/{{data_folder}}/${DATA_FOLDER_ESC}/g" $FILE
    sed -i -e "s/{{net_id}}/${TTS_NET_ID}/g" $FILE
    sed -i -e "s/{{devaddr_range}}/${TTS_DEVADDR_RANGE_ESC}/g" $FILE
    sed -i -e "s/{{pb_forwarder_prefix}}/${PB_FORWARDER_PREFIX:-}/g" $FILE
    sed -i -e "s/{{pb_home_enable}}/${PB_HOME_ENABLE}/g" $FILE
    sed -i -e "s/{{pb_forwarder_enable}}/${PB_FORWARDER_ENABLE}/g" $FILE
    sed -i -e "s/{{pb_host}}/${PB_HOST}/g" $FILE
    sed -i -e "s/{{pb_tenant_id}}/${PB_TENANT_ID}/g" $FILE
    sed -i -e "s/{{pb_oauth_id}}/${PB_OAUTH_ID}/g" $FILE
    sed -i -e "s/{{pb_oauth_secret}}/${PB_OAUTH_SECRET}/g" $FILE
    sed -i -e "s/{{pb_token}}/${PB_TOKEN}/g" $FILE
}

# Delay 5s before starting
sleep 5

# Get local IPs for Balena supervisor if running balena
if [ "$BALENA_DEVICE_UUID" != "" ]
then
    source ./balena.sh
    IP_LAN=$(balena_get_lan_ip)
    TTS_DOMAIN=${TTS_DOMAIN:-${IP_LAN%,*}}
fi

# Check domain
if [ $TTS_DOMAIN == "" ]; then
    echo -e "\033[91mERROR: TTS_DOMAIN not defined.\033[0m"
    sleep infinity
    exit 1
fi

echo "------------------------------"
echo "TTS_DOMAIN: ${TTS_DOMAIN}"
echo "------------------------------"

# Folders
HOME_FOLDER=/home/thethings/
DATA_FOLDER=/srv/data
STACK_CONFIG_FILE=${HOME_FOLDER}/ttn-lw-stack-docker.yml
CLI_CONFIG_FILE=${HOME_FOLDER}/.ttn-lw-cli.yml

# Get configuration variables
TTS_PORT=${TTS_PORT:-443}
TTS_SERVER_NAME=${TTS_SERVER_NAME:-The Things Stack}
TTS_ADMIN_EMAIL=${TTS_ADMIN_EMAIL:-admin@thethings.example.com}
TTS_NOREPLY_EMAIL=${TTS_NOREPLY_EMAIL:-noreply@thethings.example.com}
TTS_ADMIN_PASSWORD=${TTS_ADMIN_PASSWORD:-changeme}
TTS_CONSOLE_SECRET=${TTS_CONSOLE_SECRET:-console}
TTS_DEVICE_CLAIMING_SECRET=${TTS_DEVICE_CLAIMING_SECRET:-device_claiming}
TTS_METRICS_PASSWORD=${TTS_METRICS_PASSWORD:-metrics}
TTS_PPROF_PASSWORD=${TTS_PPROF_PASSWORD:-pprof}
TTS_NET_ID=${TTS_NET_ID:-000000}
TTS_DEVADDR_RANGE=${TTS_DEVADDR_RANGE:-00000000/7}

PB_HOME_ENABLE=${PB_HOME_ENABLE:-false}
PB_FORWARDER_ENABLE=${PB_FORWARDER_ENABLE:-false}
PB_HOST=${PB_HOST:-eu.packetbroker.io:443}
if [ "${PB_FORWARDER_ENABLE}" == "false" ]
then
    PB_FORWARDER_PREFIX="#"
fi

DATA_FOLDER_ESC=$(echo "${DATA_FOLDER}" | sed 's/\//\\\//g')
TTS_DEVADDR_RANGE_ESC=$(echo "${TTS_DEVADDR_RANGE}" | sed 's/\//\\\//g')
BLOCK_KEY=$(openssl rand -hex 32)
HASH_KEY=$(openssl rand -hex 64)
PB_TOKEN=$(openssl rand -hex 16)
if [ ! $TTS_SMTP_HOST == "" ]; then
    MAIL_PROVIDER="smtp"
else
    MAIL_PROVIDER="sendgrid"
fi

# Create TTS config file
cp ${STACK_CONFIG_FILE}.template ${STACK_CONFIG_FILE}
replace_placeholders ${STACK_CONFIG_FILE}

# Create CLI config file
cp ${CLI_CONFIG_FILE}.template ${CLI_CONFIG_FILE}
replace_placeholders ${CLI_CONFIG_FILE}

# Certificates are rebuild on subject change
TTS_SUBJECT_COUNTRY=${TTS_SUBJECT_COUNTRY:-ES}
TTS_SUBJECT_STATE=${TTS_SUBJECT_STATE:-Catalunya}
TTS_SUBJECT_LOCATION=${TTS_SUBJECT_LOCATION:-Barcelona}
TTS_SUBJECT_ORGANIZATION=${TTS_SUBJECT_ORGANIZATION:-TTN Catalunya}
DOMAINS=$(echo "$TTS_DOMAIN,localhost,$IP_LAN" | sed 's/,$//')
EXPECTED_SIGNATURE="$TTS_SUBJECT_COUNTRY $TTS_SUBJECT_STATE $TTS_SUBJECT_LOCATION $TTS_SUBJECT_ORGANIZATION $DOMAINS"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/certificates_signature 2> /dev/null)

if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    cd /tmp
    
    echo '{"CN":"'$TTS_SUBJECT_ORGANIZATION' CA","names":[{"C":"'$TTS_SUBJECT_COUNTRY'","ST":"'$TTS_SUBJECT_STATE'","L":"'$TTS_SUBJECT_LOCATION'","O":"'$TTS_SUBJECT_ORGANIZATION'"}],"key":{"algo":"rsa","size":2048}}' > ca.json
    cfssl genkey -initca ca.json | cfssljson -bare ca

    echo '{"CN":"'$TTS_DOMAIN'","hosts":["'$(echo $DOMAINS | sed 's/,/\",\"/g')'"],"names":[{"C":"'$TTS_SUBJECT_COUNTRY'","ST":"'$TTS_SUBJECT_STATE'","L":"'$TTS_SUBJECT_LOCATION'","O":"'$TTS_SUBJECT_ORGANIZATION'"}],"key":{"algo":"rsa","size":2048}}' > cert.json
    cfssl gencert -hostname "$DOMAINS" -ca ca.pem -ca-key ca-key.pem cert.json | cfssljson -bare cert

    cp ca.pem ${DATA_FOLDER}/ca.pem
    cp ca-key.pem ${DATA_FOLDER}/ca-key.pem
    cp cert.pem ${DATA_FOLDER}/cert.pem
    cp cert-key.pem ${DATA_FOLDER}/key.pem

    chown 886:886 ${DATA_FOLDER}/cert.pem ${DATA_FOLDER}/key.pem

    echo $EXPECTED_SIGNATURE > ${DATA_FOLDER}/certificates_signature

fi

# We populate the TC_TRUST and TC_URI for a possible Balena BasicStation service running on the same machine
if [ "$BALENA_DEVICE_UUID" != "" ]
then
    TC_TRUST=$(cat ${DATA_FOLDER}/ca.pem)
    TC_TRUST=${TC_TRUST//$'\n'/}
    balena_set_variable "TC_TRUST" "$TC_TRUST"
    balena_set_variable "TC_URI" "wss://localhost:8887"
    balena_set_label "URL" "https://$TTS_DOMAIN"
fi

# Database migration & initialization
ttn-lw-stack -c ${STACK_CONFIG_FILE} is-db migrate
if [ $? -eq 0 ]; then

    EXPECTED_SIGNATURE="$TTS_ADMIN_EMAIL $TTS_ADMIN_PASSWORD $TTS_CONSOLE_SECRET $TTS_DOMAIN"
    CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/database_signature 2> /dev/null)
    if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then


        ttn-lw-stack -c ${STACK_CONFIG_FILE} is-db create-admin-user \
            --id admin \
            --email "${TTS_ADMIN_EMAIL}" \
            --password "${TTS_ADMIN_PASSWORD}"
            
        ttn-lw-stack -c ${STACK_CONFIG_FILE} is-db create-oauth-client \
            --id cli \
            --name "Command Line Interface" \
            --owner admin \
            --no-secret \
            --redirect-uri "local-callback" \
            --redirect-uri "code"

        ttn-lw-stack -c ${STACK_CONFIG_FILE} is-db create-oauth-client \
            --id console \
            --name "Console" \
            --owner admin \
            --secret "${TTS_CONSOLE_SECRET}" \
            --redirect-uri "https://${TTS_DOMAIN}/console/oauth/callback" \
            --redirect-uri "/console/oauth/callback" \
            --logout-redirect-uri "https://${TTS_DOMAIN}/console" \
            --logout-redirect-uri "/console"

        echo $EXPECTED_SIGNATURE > ${DATA_FOLDER}/database_signature

    fi

fi

# Create admin API key and use it to login with the CLI tool
if [ "${CLI_AUTO_LOGIN}" == "true" ]; 
then

    # Check if there is a cached credentials file
    if [ -f ${DATA_FOLDER}/cli_auto_login_cache ];
    then

        # Copy back the cached credentials file
        mkdir -p ${HOME_FOLDER}/.cache/ttn-lw-cli
        cp ${DATA_FOLDER}/cli_auto_login_cache ${HOME_FOLDER}/.cache/ttn-lw-cli/cache

    else

        # Create a new API key and credentials file
        API_KEY=$( ttn-lw-stack -c ${STACK_CONFIG_FILE} is-db create-user-api-key | jq '.key' )
        mkdir -p ${HOME_FOLDER}/.cache/ttn-lw-cli
        echo "{\"by_id\":{\"${TTS_DOMAIN}\":{\"api_key\":${API_KEY},\"hosts\":[\"${TTS_DOMAIN}\"]}}}" >> ${HOME_FOLDER}/.cache/ttn-lw-cli/cache
        cp ${HOME_FOLDER}/.cache/ttn-lw-cli/cache ${DATA_FOLDER}/cli_auto_login_cache

    fi
fi

# Run server
ttn-lw-stack -c ${STACK_CONFIG_FILE} start

# Do not restart so quick
echo -e "\033[91mERROR: LNS exited, waiting 15 seconds and then rebooting service.\033[0m"
sleep 15
exit 1
