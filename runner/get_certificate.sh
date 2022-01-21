#!/bin/sh

DATA_FOLDER=/srv/data
TC_TRUST=$(cat ${DATA_FOLDER}/ca.pem)
TC_TRUST=${TC_TRUST//$'\n'/}
echo $TC_TRUST
