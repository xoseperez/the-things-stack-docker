#!/bin/sh

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

# Get configuration
CONFIG_FILE=/home/thethings/ttn-lw-stack-docker.yml
DATA_FOLDER=/srv/data
TTS_SERVER_NAME=${TTS_SERVER_NAME:-The Things Stack}
TTS_ADMIN_EMAIL=${TTS_ADMIN_EMAIL:-admin@thethings.example.com}
TTS_NOREPLY_EMAIL=${TTS_NOREPLY_EMAIL:-noreply@thethings.example.com}
TTS_ADMIN_PASSWORD=${TTS_ADMIN_PASSWORD:-changeme}
TTS_CONSOLE_SECRET=${TTS_CONSOLE_SECRET:-console}
TTS_DEVICE_CLAIMING_SECRET=${TTS_DEVICE_CLAIMING_SECRET:-device_claiming}
TTS_METRICS_PASSWORD=${TTS_METRICS_PASSWORD:-metrics}
TTS_PPROF_PASSWORD=${TTS_PPROF_PASSWORD:-pprof}

DATA_FOLDER_ESC=$(echo "${DATA_FOLDER}" | sed 's/\//\\\//g')
BLOCK_KEY=$(openssl rand -hex 32)
HASH_KEY=$(openssl rand -hex 64)
if [ ! $TTS_SMTP_HOST == "" ]; then
    MAIL_PROVIDER="smtp"
else
    MAIL_PROVIDER="sendgrid"
fi

# Build config file
cp ${CONFIG_FILE}.template ${CONFIG_FILE}
sed -i -e "s/{{server_name}}/${TTS_SERVER_NAME}/g" $CONFIG_FILE
sed -i -e "s/{{admin_email}}/${TTS_ADMIN_EMAIL}/g" $CONFIG_FILE
sed -i -e "s/{{noreply_email}}/${TTS_NOREPLY_EMAIL}/g" $CONFIG_FILE
sed -i -e "s/{{console_secret}}/${TTS_CONSOLE_SECRET}/g" $CONFIG_FILE
sed -i -e "s/{{domain}}/${TTS_DOMAIN}/g" $CONFIG_FILE
sed -i -e "s/{{mail_provider}}/${MAIL_PROVIDER}/g" $CONFIG_FILE
sed -i -e "s/{{sendgrid_key}}/${TTS_SENDGRID_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_host}}/${TTS_SMTP_HOST}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_user}}/${TTS_SMTP_USER}/g" $CONFIG_FILE
sed -i -e "s/{{smtp_pass}}/${TTS_SMTP_PASS}/g" $CONFIG_FILE
sed -i -e "s/{{block_key}}/${BLOCK_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{hash_key}}/${HASH_KEY}/g" $CONFIG_FILE
sed -i -e "s/{{metrics_password}}/${TTS_METRICS_PASSWORD}/g" $CONFIG_FILE
sed -i -e "s/{{pprof_password}}/${TTS_PPROF_PASSWORD}/g" $CONFIG_FILE
sed -i -e "s/{{device_claiming_secret}}/${TTS_DEVICE_CLAIMING_SECRET}/g" $CONFIG_FILE
sed -i -e "s/{{data_folder}}/${DATA_FOLDER_ESC}/g" $CONFIG_FILE

# Certificates are rebuild on subject change
TTS_SUBJECT_COUNTRY=${TTS_SUBJECT_COUNTRY:-ES}
TTS_SUBJECT_STATE=${TTS_SUBJECT_STATE:-Catalunya}
TTS_SUBJECT_LOCATION=${TTS_SUBJECT_LOCATION:-Barcelona}
TTS_SUBJECT_ORGANIZATION=${TTS_SUBJECT_ORGANIZATION:-TTN Catalunya}
EXPECTED_SIGNATURE="$TTS_SUBJECT_COUNTRY $TTS_SUBJECT_STATE $TTS_SUBJECT_LOCATION $TTS_SUBJECT_ORGANIZATION $TTS_DOMAIN"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/certificates_signature 2> /dev/null)

if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    cd /tmp
    
    echo '{"CN":"'$TTS_SUBJECT_ORGANIZATION CA'","key":{"algo":"rsa","size":2048},"names":[{"C":"'$TTS_SUBJECT_COUNTRY'","ST":"'$TTS_SUBJECT_STATE'","L":"'$TTS_SUBJECT_LOCATION'","O":"'$TTS_SUBJECT_ORGANIZATION'"}]}' > ca.json
    cfssl genkey -initca ca.json | cfssljson -bare ca

    echo '{"CN":"'$TTS_DOMAIN'","hosts":["'$TTS_DOMAIN'","localhost","'$(echo $IP_LAN | sed 's/,/\",\"/')'"],"key":{"algo":"rsa","size":2048},"names":[{"C":"'$TTS_SUBJECT_COUNTRY'","ST":"'$TTS_SUBJECT_STATE'","L":"'$TTS_SUBJECT_LOCATION'","O":"'$TTS_SUBJECT_ORGANIZATION'"}]}' > cert.json
    cfssl gencert -hostname "$TTS_DOMAIN,localhost,$IP_LAN" -ca ca.pem -ca-key ca-key.pem cert.json | cfssljson -bare cert

    cp ca.pem ${DATA_FOLDER}/ca.pem
    cp ca-key.pem ${DATA_FOLDER}/ca-key.pem
    cp cert.pem ${DATA_FOLDER}/cert.pem
    cp cert-key.pem ${DATA_FOLDER}/key.pem

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

# Database initialization
EXPECTED_SIGNATURE="$TTS_ADMIN_EMAIL $TTS_ADMIN_PASSWORD $TTS_CONSOLE_SECRET $TTS_DOMAIN"
CURRENT_SIGNATURE=$(cat ${DATA_FOLDER}/database_signature 2> /dev/null)
if [ "$CURRENT_SIGNATURE" != "$EXPECTED_SIGNATURE" ]; then

    ttn-lw-stack -c ${CONFIG_FILE} is-db init
    
    if [ $? -eq 0 ]; then

        ttn-lw-stack -c ${CONFIG_FILE} is-db create-admin-user \
            --id admin \
            --email "${TTS_ADMIN_EMAIL}" \
            --password "${TTS_ADMIN_PASSWORD}"
            
        ttn-lw-stack -c ${CONFIG_FILE} is-db create-oauth-client \
            --id cli \
            --name "Command Line Interface" \
            --owner admin \
            --no-secret \
            --redirect-uri "local-callback" \
            --redirect-uri "code"

        ttn-lw-stack -c ${CONFIG_FILE} is-db create-oauth-client \
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

# Run server
ttn-lw-stack -c ${CONFIG_FILE} start

# Do not restart so quick
echo -e "\033[91mERROR: LNS exited, waiting 60 seconds and then rebooting service.\033[0m"
sleep 60
exit 1
