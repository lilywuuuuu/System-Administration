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

# while true;do
# 	ls -tr /usr/home/sftp/public | awk '/.exe/ {print $1}'| while read line; do
# 		p="/usr/home/sftp/public/$line"
# 		who=$(stat -f '%Su' $p)
#         new_path="/home/sftp/hidden/.exe/${line}"
#         mv "$p" "$new_path"
#         logger -p local4.info "$p violate file detected. Uploaded by ${who}."	
# 	done
# 	sleep 0.01 
# done