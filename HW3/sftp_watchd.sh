#!/usr/local/bin/bash

directory="/home/sftp/public/"
destination="/home/sftp/hidden/.exe/"

files=$(find "$directory" -type f -name "*.exe")
for file in $files; do
    # username=$(getent passwd ${uid} | cut -d: -f1)
    username=$(stat sftp_watchd.sh | awk '{print $5}')
    mv "$file" "$destination"
    echo "${directory}${file} violate file detected. Uploaded by ${username}." | logger -p local1.warning
done
