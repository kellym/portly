#!/bin/bash

# SEE portly/chef FOR THE ACTIVE SCRIPT

# This script runs when a user starts a forwarding agent.
local_cid="${CID//[^0-9]/}"
client_token="${TOKEN//[^0-9A-Za-z]}"
redis_key="watching:$client_token"
redis_port=6380

function redis-client() {
    FD=${1}
    shift;
    if [ ${#} -ne 0 ]; then # always use unified protocol and let the server validate the number of parameters
        local ARRAY=( "${@}" )
        local CMD=("*$[${#ARRAY[@]}]")
        local i=0
        for ((i=0;i<${#ARRAY[@]};i++)); do
            CMD=( "${CMD[@]}" "\$${#ARRAY[${i}]}" "${ARRAY[${i}]}" )
        done
        printf "%s\r\n" "${CMD[@]}" >&${FD}
    fi
    local ARGV
    read -r -u ${FD}
    REPLY=${REPLY:0:${#REPLY}-1}
    case ${REPLY} in
        -*|\$-*) # error message
            echo "${REPLY:1}"
            return 1;;
        \$*) # message size
            [ ${BASH_VERSINFO} -eq 3 ] && SIZEDELIM="n"
            [ ${REPLY:1} -gt 0 ] && read -r -${SIZEDELIM:-N} $[${REPLY:1}+2] -u ${FD} # read again to get the value itself
            ARGV=( "${REPLY:0:$[${#REPLY}-$[${BASH_VERSINFO}-2]]}" );;
        :*) # integer message
            ARGV=( "${REPLY:1}" );;
        \**) # bulk reply - recursive based on number of messages
            unset ARGV
            for ((ARGC="${REPLY:1}";${ARGC}>0;ARGC--)); do
                ARGV=("${ARGV[@]}" $(redis-client ${FD}))
            done;;
        +*) # standard message
            ARGV=( "${REPLY:1}" );;
        *) # wtf? just in case...
            ARGV=( "${ARGV[@]}" "${REPLY}" );;
    esac
    printf "%s\n" "${ARGV[@]}"
}

function on_exit()
{
  # this is where we need to ping our API to kill the connection
  echo $CID
  curl -i -H "Accept: application/json" -X DELETE "http://localhost:9393/api/tunnels/$local_cid?access_token=$client_token&publish=false"
}

trap on_exit EXIT

start_time=`date +%s`

while true
do
  exec 6<>/dev/tcp/localhost/$redis_port # open the connection
  result=$(redis-client 6 SISMEMBER $redis_key "$local_cid")
  #free_time=$(redis-client 6 HGET free_time "$client_token")
  free_time=$(psql -d $dbname -U $username -h localhost -p 5432 -t -c "SELECT 1")
  exec 6>&- # close the connection
  if [ "$result" = "0" ]; then
    exit
  fi
  # if it's a free account and it's more than X minutes open, disconnect
  if [ "$free_time" != "-1" ] && [ "$((`date +%s` - $start_time > (60 * $free_time) ))" = "1" ]; then
    exit
  fi
  echo 'HI'
  sleep 5
done
