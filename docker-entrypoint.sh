#!/bin/bash
set -e

RUN_ONCE="${RUN_ONCE:-false}"
SCHEDULE_TIME="${SCHEDULE_TIME:-03:00}"
FEEDS_FILE="${FEEDS_FILE:-/config/feeds.json}"
DOWNLOAD_FOLDER="${DOWNLOAD_FOLDER:-/downloads}"

echo "Podcast Bulk Downloader - Docker Mode"
echo "======================================="
echo "Schedule time: ${SCHEDULE_TIME}"
echo "Feeds file: ${FEEDS_FILE}"
echo "Download folder: ${DOWNLOAD_FOLDER}"
echo "Run once: ${RUN_ONCE}"
echo ""

download_episodes() {
    echo "[$(date)] Checking for new episodes..."
    
    if [ ! -f "${FEEDS_FILE}" ]; then
        echo "ERROR: Feeds file not found: ${FEEDS_FILE}"
        return 1
    fi
    
    feeds=$(python -c "
import json
import sys

with open('${FEEDS_FILE}', 'r') as f:
    config = json.load(f)

for feed in config.get('feeds', []):
    url = feed.get('url', '')
    subfolder = feed.get('subfolder', 'default')
    prefix = feed.get('prefix', 'NO_PREFIX')
    last_n = feed.get('last_n', 1)
    overwrite = feed.get('overwrite', False)
    
    if url:
        print(f'{url}|{subfolder}|{prefix}|{last_n}|{overwrite}')
")
    
    while IFS='|' read -r feed_url subfolder prefix last_n overwrite; do
        if [ -z "$feed_url" ]; then
            continue
        fi
        
        target_folder="${DOWNLOAD_FOLDER}/${subfolder}"
        mkdir -p "$target_folder"
        
        echo "Processing feed: $feed_url -> $target_folder (prefix=$prefix, last_n=$last_n, overwrite=$overwrite)"
        
        python -c "
import os
os.makedirs('${target_folder}', exist_ok=True)

from src.bulk_downloader import download_mp3s, Prefix

prefix_map = {'NO_PREFIX': Prefix.NO_PREFIX, 'DATE': Prefix.DATE, 'DATE_TIME': Prefix.DATE_TIME}

download_mp3s(
    url='${feed_url}',
    folder='${target_folder}',
    last_n=${last_n},
    overwrite=${overwrite},
    prefix=prefix_map.get('${prefix}', Prefix.NO_PREFIX)
)
" || echo "Failed to download from $feed_url"
        
        echo "Done processing: $feed_url"
        echo "---"
    done <<< "$feeds"
    
    echo "[$(date)] Download check complete"
}

if [ "$RUN_ONCE" = "true" ]; then
    echo "Running once mode..."
    download_episodes
else
    echo "Running in scheduled mode..."
    while true; do
        current_time=$(date +%H:%M)
        target_time="$SCHEDULE_TIME"
        
        current_seconds=$(date +%s -d "$current_time")
        target_seconds=$(date +%s -d "$target_time")
        
        if [ "$current_seconds" -lt "$target_seconds" ]; then
            sleep_seconds=$((target_seconds - current_seconds))
        else
            sleep_seconds=$((86400 - current_seconds + target_seconds))
        fi
        
        echo "Next check in ${sleep_seconds} seconds at ${SCHEDULE_TIME}"
        sleep $sleep_seconds
        
        download_episodes
    done
fi