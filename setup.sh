#!/bin/sh

# UptimeToolbox Agent Installer (uptimetoolbox.com)

NODE=""
TOKEN=""
SERVER=""
while getopts ':n:t:s:' flag; do
  case "${flag}" in
    n) NODE=${OPTARG} ;;
    t) TOKEN=${OPTARG} ;;
    s) SERVER=${OPTARG} ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit 1
      ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

if [ -z "${NODE}" ]; then
  echo "node (-n) argument not provided"
  exit 1
fi

if [ -z "${TOKEN}" ]; then
  echo "token (-n) argument not provided"
  exit 1
fi

if [ -z "${SERVER}" ]; then
  echo "server (-s) argument not provided"
  exit 1
fi

SERVER_PATH=${SERVER}/api/v1/node-response/

# Uninstall old versions
printf '\nRemoving old versions\n'
if [ -x "$(command -v systemctl)" ] && [ -e '/etc/systemd/system/uptimetoolbox.timer' ]; then
  systemctl -q disable uptimetoolbox.timer
fi
if [ -x "$(command -v crontab)" ]; then
  crontab -l | grep -v '/uptimetoolbox/agent.sh' | crontab -
fi
rm -rf /opt/uptimetoolbox
rm -rf /etc/systemd/system/uptimetoolbox.*

# Check if using systemd or init
is_systemd='false'
if ps -p 1 | grep -q 'systemd'; then
  printf 'Systemd detected\n'
  is_systemd='true'
fi

# check if cron service is enable
has_cron='false'
if pgrep -x cron > /dev/null || pgrep -x crond > /dev/null; then
  printf 'Cron detected\n'
  has_cron='true'
fi

if [ "$is_systemd" = 'false' ] && [ "$has_cron" = 'false' ]; then
  printf 'systemd unavailable. cron unavailable\n'
  printf 'please install cron and try again\n'
  printf 'Install Failed\n'
  exit 1
fi

printf 'Fetching agent.............'
mkdir -p /opt/uptimetoolbox
curl -s https://raw.githubusercontent.com/uptimetoolbox/uptimetoolbox-agent/v1.0.0/agent.sh --output /opt/uptimetoolbox/agent.sh
chmod u+x /opt/uptimetoolbox/agent.sh
printf 'done\n'

sed -i "s/{{ node }}/${NODE}/" /opt/uptimetoolbox/agent.sh
sed -i "s/{{ token }}/${TOKEN}/" /opt/uptimetoolbox/agent.sh
sed -i "s~{{ server }}~${SERVER}~" /opt/uptimetoolbox/agent.sh  # alt delimiter for url compatibility

# IF SYSTEMD
if [ "$is_systemd" = 'true' ]; then
  printf 'Using systemd..............'

  # Note: Heredoc lines are TAB delimited. Spaces will not work
  cat > /etc/systemd/system/uptimetoolbox.service <<-EOD
	[Unit]
	Description=Runs UptimeToolbox Agent

	[Service]
	Type=oneshot
	ExecStart=/bin/sh -c '/opt/uptimetoolbox/agent.sh'
EOD

  cat > /etc/systemd/system/uptimetoolbox.timer <<-EOD
	[Unit]
	Description=Run uptimetoolbox.service every minute

	[Timer]
	OnCalendar=*:0/1
	Unit=uptimetoolbox.service

	[Install]
	WantedBy=multi-user.target
EOD

  systemctl daemon-reload
  systemctl start uptimetoolbox.service     # run initial job
  systemctl start uptimetoolbox.timer       # start timer service
  systemctl -q enable uptimetoolbox.timer   # run timer on boot
  printf 'done\n'

else

  # NO SYSTEMD, TRY CRON
  if [ "$has_cron" = 'true' ]; then

    printf 'Adding crontab entry.......'
    (crontab -l 2>/dev/null; printf '*/1 * * * * /bin/sh /opt/uptimetoolbox/agent.sh\n') | crontab -
    printf 'done\n'

  fi  # END has_cron

fi # end is_systemd

printf 'Initializing...............'
/bin/sh /opt/uptimetoolbox/agent.sh -i > /dev/null
sleep 3
printf 'done\n'

printf 'Sending initial packet.....'
/bin/sh /opt/uptimetoolbox/agent.sh
printf 'done\n\n'

printf 'Installation Successful\n\n'
