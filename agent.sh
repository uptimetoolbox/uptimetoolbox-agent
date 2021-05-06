#!/bin/sh

# UptimeToolbox (uptimetoolbox.com)

# Flags for experimental features
zfsflag='false'
dockerflag='false'
verbose='false'
initialize='false'
while getopts 'zdvi' flag; do
  case "${flag}" in
    z) zfsflag='true' ;;
    d) dockerflag='true' ;;
    v) verbose='true' ;;
    i) initialize='true' ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done

NODE={{ node }}
TOKEN={{ token }}
SERVER={{ server }}
SERVER_PATH=${SERVER}/api/v1/node-response/

# trim whitespace
trim () {
  echo "$1" | xargs
}

digits () {
  echo "$1" | sed 's/[^0-9]*//g'
}

# Fetch System info
if [ -f /etc/os-release ]; then
    . /etc/os-release
    os_name=${NAME}
    os_version=${VERSION_ID}
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    os_name=${DISTRIB_ID}
    os_version=${DISTRIB_RELEASE}
elif [ -f /etc/system-release ]; then
    os_name=$(cat /etc/system-release | awk '{print $1}')
    os_version=$(cat /etc/system-release)
else
    os_name=$(uname -s)
    os_version=$(uname -r)
fi

hostname=$( hostname -f )
kernel_name=$( uname -s )
kernel_release=$( uname -r )

ram_size=$()

cpu_architecture=$( uname -m )
cpu_model=$( cat /proc/cpuinfo | grep 'model name' -m 1 | awk -F\: '{ print $2 }' )
cpu_cores=$( cat /proc/cpuinfo | grep 'model name' | wc -l )
cpu_frequency=$(trim "$( lscpu | grep 'CPU MHz' |  awk -F\: '{ print $2 }' )" )
cpu_max_frequency=$(trim "$( lscpu | grep 'CPU max MHz' |  awk -F\: '{ print $2 }' )" )

uptime=$( cat /proc/uptime | awk '{print $1}' )
process_count=$( ps aux | wc -l )
file_handles_current=$( sysctl fs.file-nr | sed 's/\t/  /g'  | awk '{ print $3 }' ) # result contains tabs
file_handles_max=$( sysctl fs.file-nr | sed 's/\t/  /g' | awk '{ print $5 }' ) # can be as high as 9223372036854775807

ram_total=$(digits "$( cat /proc/meminfo | grep '^MemTotal:' | grep 'kB' | awk -F\: '{ print $2 }' )" )
ram_free=$(digits "$( cat /proc/meminfo | grep '^MemFree:' | grep 'kB' | awk -F\: '{ print $2 }' )" )
ram_available=$(digits "$( cat /proc/meminfo | grep '^MemAvailable:' | grep 'kB' | awk -F\: '{ print $2 }' )" )
ram_buffers=$(digits "$( cat /proc/meminfo | grep '^Buffers:' | grep 'kB' | awk -F\: '{ print $2 }' )" )
ram_cached=$(digits "$( cat /proc/meminfo | grep '^Cached:' | grep 'kB' | awk -F\: '{ print $2 }' )" )

disk_total=$( df -PTk | grep -Ee '\S+\s+(ext[234]|vfat|xfs|simfs)' | grep -v -Ee '(^/dev/zd|\S+\s+zfs)' | awk '{ print $3 }' | paste -sd+ - | bc )
disk_used=$( df -PTk | grep -Ee '\S+\s+(ext[234]|vfat|xfs|simfs)' | grep -v -Ee '(^/dev/zd|\S+\s+zfs)' | awk '{ print $4 }' | paste -sd+ - | bc )

## SNAPSHOT DATA
# Fetch previous cpu snapshot data
prev_cpu_user=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $2 }' )
prev_cpu_nice=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $3 }' )
prev_cpu_system=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $4 }' )
prev_cpu_idle=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $5 }' )
prev_cpu_iowait=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $6 }' )
prev_cpu_irq=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $7 }' )
prev_cpu_softirq=$( cat /tmp/ut_data.stat | grep '^cpu:cpu ' | awk '{ print $8 }' )

# Fetch previous network snapshot data
prev_network_receive=$( cat /tmp/ut_data.stat | grep '^network_receive: ' | awk '{ print $2 }' )
prev_network_transmit=$( cat /tmp/ut_data.stat | grep '^network_transmit: ' | awk '{ print $2 }' )

# Fetch previous uptime data (needed for network calculations)
prev_uptime=$( cat /tmp/ut_data.stat | grep '^uptime: ' | awk '{ print $2 }' )

# FETCH CURRENT
# fetch current cpu data
cur_cpu_user=$( cat /proc/stat | grep '^cpu ' | awk '{ print $2 }' )
cur_cpu_nice=$( cat /proc/stat | grep '^cpu ' | awk '{ print $3 }' )
cur_cpu_system=$( cat /proc/stat | grep '^cpu ' | awk '{ print $4 }' )
cur_cpu_idle=$( cat /proc/stat | grep '^cpu ' | awk '{ print $5 }' )
cur_cpu_iowait=$( cat /proc/stat | grep '^cpu ' | awk '{ print $6 }' )
cur_cpu_irq=$( cat /proc/stat | grep '^cpu ' | awk '{ print $7 }' )
cur_cpu_softirq=$( cat /proc/stat | grep '^cpu ' | awk '{ print $8 }' )

# Network details (exclude loopback)
cur_network_receive=$( cat /proc/net/dev | grep -v -e 'Inter' -e 'face' -e 'lo:' | awk '{net+=$2} ; END {print net}' )
cur_network_transmit=$( cat /proc/net/dev | grep -v -e 'Inter' -e 'face' -e 'lo:' | awk '{net+=$10} ; END {print net}' )


# UPDATE SNAPSHOT DATA
echo "cpu:$( cat /proc/stat | grep '^cpu ')" > /tmp/ut_data.stat
echo "network_receive: ${cur_network_receive}" >> /tmp/ut_data.stat
echo "network_transmit: ${cur_network_transmit}" >> /tmp/ut_data.stat
echo "uptime: ${uptime}" >> /tmp/ut_data.stat


# returns /proc/stat values if ut_data.stat doesn't exist
cpu_user=$(( cur_cpu_user - prev_cpu_user ))
cpu_nice=$(( cur_cpu_nice - prev_cpu_nice ))
cpu_system=$(( cur_cpu_system - prev_cpu_system ))
cpu_idle=$(( cur_cpu_idle - prev_cpu_idle ))
cpu_iowait=$(( cur_cpu_iowait - prev_cpu_iowait ))
cpu_irq=$(( cur_cpu_irq - prev_cpu_irq ))
cpu_softirq=$(( cur_cpu_softirq - prev_cpu_softirq ))

cpu_usage=$( echo "scale=2 ; 100 - ((${cpu_idle} * 100) / (${cpu_user} + ${cpu_nice} + ${cpu_system} + ${cpu_idle} + ${cpu_iowait} + ${cpu_irq} + ${cpu_softirq}))" | bc )
ram_usage=$( echo "scale=2 ; 100 - ((${ram_available}  * 100 ) / ${ram_total})" | bc )  # Other values are null if server off.
disk_usage=$( echo "scale=2 ; ((${disk_used}  * 100 ) / ${disk_total})" | bc )

uptime_delta=$( echo "scale=2 ; ${uptime} - ${prev_uptime}" | bc )

network_receive=$( echo "scale=2 ; (${cur_network_receive} - ${prev_network_receive}) / ${uptime_delta} " | bc )  # bytes per second
network_transmit=$( echo "scale=2 ; (${cur_network_transmit} - ${prev_network_transmit}) / ${uptime_delta} " | bc )  # bytes per second

ip_list=$( ip -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " ") ; print $2, $4}' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' )

DISK_SIZE_JSON=$( df -Tk | grep -Ee '\S+\s+(ext[234]|vfat|xfs|simfs)' | awk '{ print "{\"fs\": \"" $1 "\",\"type\": \"" $2 "\",\"blocks\": " $3 ",\"used\": " $4 ",\"avail\": " $5 ",\"use\": \"" $6 "\",\"mounted_on\": \"" $7 "\"}" }' | paste -sd, )
DISK_INODE_JSON=$( df -Tik | grep -Ee '\S+\s+(ext[234]|vfat|xfs|simfs)' | awk '{ print "{\"fs\": \"" $1 "\",\"type\": \"" $2 "\",\"inodes\": " $3 ",\"iused\": " $4 ",\"ifree\": " $5 ",\"iuse\": \"" $6 "\",\"mounted_on\": \"" $7 "\"}" }' | paste -sd, )

# Fetch bulky data to process on server
RAW_CPU_DATA=$( cat /proc/stat | grep cpu | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' )
RAW_NETWORK_DATA=$( cat /proc/net/dev | grep -v -e 'Inter' -e 'face' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' ) # Exclude first 2 lines
RAW_PROCESS_CPU_DATA=$( ps aux | grep -v COMMAND | awk '{arr[$11]+=$3} ; END {for (key in arr) print arr[key],key}' | sort -rnk1 | head -n 10 | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' ) # Sort by Cpu Usage
RAW_PROCESS_RAM_DATA=$( ps aux | grep -v COMMAND | awk '{arr[$11]+=$4} ; END {for (key in arr) print arr[key],key}' | sort -rnk1 | head -n 10 | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' ) # Sort by Ram Usage

if [ "${zfsflag}" = 'true' ] ; then
    RAW_ZFS_DATA=$( zpool list | grep -v -Ee '^NAME' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'  )
fi

if [ "${dockerflag}" = 'true' ] ; then
    RAW_DOCKER_DATA=$( docker stats --no-stream --no-trunc | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g' )
fi

CONTENT=$(cat << END
{
    "node": "${NODE}",

    "hostname": "${hostname}",
    "os_name": "${os_name}",
    "os_version": "${os_version}",
    "kernel_name": "${kernel_name}",
    "kernel_release": "${kernel_release}",

    "uptime": "${uptime}",
    "process_count": "${process_count}",
    "file_handles_current": "${file_handles_current}",
    "file_handles_max": "${file_handles_max}",

    "ram_total": "${ram_total}",
    "ram_free": "${ram_free}",
    "ram_available": "${ram_available}",
    "ram_buffers": "${ram_buffers}",
    "ram_cached": "${ram_cached}",

    "cpu_model": "${cpu_model}",
    "cpu_cores": "${cpu_cores}",
    "cpu_frequency": "${cpu_frequency}",
    "cpu_max_frequency": ${cpu_max_frequency:-null},
    "cpu_architecture": "${cpu_architecture}",

    "cpu_usage": "${cpu_usage}",
    "ram_usage": "${ram_usage}",
    "disk_usage": "${disk_usage}",
    "network_receive": "${network_receive}",
    "network_transmit": "${network_transmit}",

    "cpu_user": "${cpu_user}",
    "cpu_nice": "${cpu_nice}",
    "cpu_system": "${cpu_system}",
    "cpu_idle": "${cpu_idle}",
    "cpu_iowait": "${cpu_iowait}",
    "cpu_irq": "${cpu_irq}",
    "cpu_softirq": "${cpu_softirq}",

    "ip_list": "${ip_list}",
    "disk_json": {"data": [${DISK_SIZE_JSON}] },
    "inode_json": {"data": [${DISK_INODE_JSON}] },

    "cpu_raw": "${RAW_CPU_DATA}",
    "network_raw": "${RAW_NETWORK_DATA}",
    "process_cpu": "${RAW_PROCESS_CPU_DATA}",
    "process_ram": "${RAW_PROCESS_RAM_DATA}",

    "zfs": "${RAW_ZFS_DATA}",
    "docker": "${RAW_DOCKER_DATA}"
}
END
)

# Don't send values
# Useful for skipping over initial, misleading, data
if [ "${initialize}" = 'true' ] ; then
  exit 0
fi

if [ "${verbose}" = 'true' ] ; then
    echo "${CONTENT}"
    curl -i -H "Content-Type: application/json" -H "X-NODE-TOKEN: ${TOKEN}" -X POST --data "${CONTENT}" ${SERVER_PATH}
    printf '\n'
else
    curl -s -H "Content-Type: application/json" -H "X-NODE-TOKEN: ${TOKEN}" -X POST --data "${CONTENT}" ${SERVER_PATH} > /dev/null
fi

