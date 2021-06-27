#!/bin/bash
set -e

if [ -z "${ENDPOINT}" ]; then
    ENDPOINT=https://ingest.uptimetoolbox.com
fi

if [ -z "${ORGANIZATION_ID}" ]; then
    echo "ORGANIZATION_ID environment variable is required"
    exit 1
fi

if [ -z "${API_KEY}" ]; then
    echo "API_KEY environment variable is required"
    exit 1
fi

# Get or Create machine identifier
hostname=$( docker info --format '{{ .Name}}' )
primary_mac=$( ip a | grep link/ether | head -n 1 | awk '{ print $2 }' )
NODE_GUID="${hostname}_${primary_mac}"

if [ -z "${NODE_GUID}" ]; then
    echo "Unable to fetch GUID"
fi

# Get node_id from identifier
status_code=$(curl --write-out %{http_code} --silent --output /opt/uptimetoolbox/node_id.txt \
                -H "X-ORG-ID: ${ORGANIZATION_ID}" \
                -H "X-NODE-API-KEY: ${API_KEY}" \
                ${ENDPOINT}/api/v1/node/by-guid/${NODE_GUID}/)

# Verify request
if [ "${status_code}" = '200' ] || [ "${status_code}" = '201' ] ; then
    echo "Authentication successful"
else
    echo "Unable to authenticate. Status: ${status_code}"
    exit 1
fi

NODE=$(cat /opt/uptimetoolbox/node_id.txt | cut -f1 -d\;)
TOKEN=$(cat /opt/uptimetoolbox/node_id.txt | cut -f2 -d\;)
SERVER=$ENDPOINT

sed -i "s/{{ node }}/${NODE}/" /opt/uptimetoolbox/agent.sh
sed -i "s/{{ token }}/${TOKEN}/" /opt/uptimetoolbox/agent.sh
sed -i "s~{{ server }}~${SERVER}~" /opt/uptimetoolbox/agent.sh  # alt delimiter for url compatibility

printf 'creating crontab entry...'
(crontab -l 2>/dev/null; printf "*/1 * * * * /bin/bash /opt/uptimetoolbox/agent.sh -c \n") | crontab -
printf 'done\n'

# Initial run
/bin/bash /opt/uptimetoolbox/agent.sh

# Start cron
crond -f
