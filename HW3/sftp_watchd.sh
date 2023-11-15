#!/bin/sh

directory="/home/sftp/public/"
destination="/home/sftp/hidden/.exe/"

while true; do 
    files=$(find "$directory" -type f -name "*.exe")
    for file in $files; do
        username=$(stat ${file} | awk '{print $5}')
        echo "${directory}${file} violate file detected. Uploaded by ${username}." | logger -p local1.warning
        mv "$file" "$destination"
    done
    sleep 0.01
done 
