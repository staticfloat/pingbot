#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}"

mkdir -p data

# Write every thing out to a file as well
exec > >(tee -a ./data/pinger.log) 2>&1

# timeit stores the time (in seconds) in `TIME`
TIME=""
function timeit()
{
    local start=$(date "+%s.%N")
    "$@"
    local RET="$?"
    local stop=$(date "+%s.%N")

    # Calculate elapsed time, store in `$TIME`
    TIME="$(echo "$stop - $start" | bc -l)"

    # Return actual return value
    return "${RET}"
}

# We're going to measure a few things and store the results in `.csv` files:
while [ true ]; do
    DATE="$(date "+%s")"
    DATE_STR="$(date --date="@${DATE}")"
    echo "[${DATE}] ${DATE_STR}"

    # 1. Can we reach https://google.com?
    timeit curl -fsL https://google.com --connect-timeout 5.0 -o ./data/google.data
    SUCCESS="$?"
    DATA_TRANSFERRED="$(stat -c "%s" ./data/google.data)"

    # Store how long it took, and how much data was transferred
    echo "$DATE,$SUCCESS,$TIME,$DATA_TRANSFERRED" >> ./data/google-curl.log.csv
    echo "  - curl: exit code $SUCCESS, in $(printf "%.3fs" "$TIME"), with $DATA_TRANSFERRED bytes"


    # 2. Use `trippy` to do a traceroute:
    echo "# $DATE - ${DATE_STR}" >> ./data/google-trippy.log.csv
    sudo trippy google.com -p tcp -P 443 -m csv >> ./data/google-trippy.log.csv
    CSV_LINE=$(tail -1 ./data/google-trippy.log.csv)
    NUM_HOPS="$(cut -d, -f 3 <<<"${CSV_LINE}")"
    NUM_SENT="$(cut -d, -f 7 <<<"${CSV_LINE}")"
    NUM_RCVD="$(cut -d, -f 8 <<<"${CSV_LINE}")"
    AVG_MS="$(cut -d, -f 10 <<<"${CSV_LINE}")"
    echo "  - trippy: ${NUM_HOPS} hops, received ${NUM_RCVD}/${NUM_SENT} with avg latency ${AVG_MS}ms"


    # 3. Use `fast` to do a quick speedtest from Netflix
    SPEED_IN_MBPS="$(fast --silent -m)"
    echo "${DATE},${SPEED_IN_MBPS}">> ./data/fast.csv
    echo "  - fast: ${SPEED_IN_MBPS} Mbps"

    # Sleep for 60s
    sleep 60
    echo
done
