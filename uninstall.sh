#!/bin/sh
#
# UptimeToolbox Agent Uninstaller (uptimetoolbox.com)

if [ -x "$(command -v crontab)" ]; then
  printf '\nRemoving crontab entry\n'
  crontab -l | grep -v '/uptimetoolbox/agent.sh' | crontab -
fi

if [ -f /etc/systemd/system/uptimetoolbox.service ] || [ -f /etc/systemd/system/uptimetoolbox.timer ]; then
  printf '\nRemoving systemd service\n'
  systemctl -q disable uptimetoolbox.timer
  rm -rf /etc/systemd/system/uptimetoolbox.*
fi

if [ -d /opt/uptimetoolbox ]; then
  printf 'Removing agent scripts\n'
  rm -rf /opt/uptimetoolbox
fi

if [ -f /tmp/ut_data.stat ]; then
  printf 'Cleaning up temporary files\n'
  rm -rf /tmp/ut_data.stat
fi

if ps -p 1 | grep -q 'systemd'; then
  printf 'Reloading systemd\n'
  systemctl daemon-reload
fi

printf "\nUptimeToolbox agent removed successfully\n\n"