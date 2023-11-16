#!/usr/local/bin/bash

function help() {
cat << EOF
Usage:
- create: zfsbak DATASET [ROTATION_CNT]
- list: zfsbak -l|--list [DATASET|ID|DATASET ID...]
- delete: zfsbak -d|--delete [DATASET|ID|DATASET ID...]
- export: zfsbak -e|--export DATASET [ID]
- import: zfsbak -i|--import FILENAME DATASET
EOF
}

function datetime() {
    # date +output format
    date '+%Y-%m-%d-%H:%M:%S'
}

function zfs_snap() {
    echo "Snap $1"
    zfs snapshot "$1"
}

function zfs_destroy() {
    echo "Destroy $1"
    zfs destroy "$1"
}

function parse_dataset_id() {
    dataset="mypool"
    ids=()
    if [ -n "$1" ]; then
        # must use [[]]! -> provide additional features for conditional statements in bash
        if [[ "$1" != mypool* ]]; then 
            ids=("$@") # id may be $1
        else
            dataset="$1"
            if [ -n "$2" ]; then
                ids=("${@:2}")
            fi
        fi 
    fi
}

function zfs_list() {
    # -H -> no header
    # -o name -> only show name column
    # -r -> recursively show datasets inside a dataset if there's any
    # -t snapshot -> only include snapshots 
    # $1 -> name of the snapshot
    snapshots=$(zfs list -H -o name -r -t snapshot "$1") 
    if [ -z "$snapshots" ]; then
        return # return if there's no snapshots
    fi
    # sort snapshots based on their creation time
    # using '@' as the field separator
    sorted_snapshots=$(echo "$snapshots" | sort -t '@' -k 2)
    # add a line number (NR) before each output
    numbered_snapshots=$(echo "$sorted_snapshots" | awk '{print NR "\t" $0}')
    # only output the snapshot that starts with $2 (ID) if there is one
    filtered_snapshots=$(echo "$numbered_snapshots" | grep "^$2")
    if [ -z "$filtered_snapshots" ]; then
        return # return if there's no snapshots
    fi
    echo "$filtered_snapshots"
}

function zfsbak_list() {
    parse_dataset_id "$@"
    echo -e "ID\tDATASET\t\tTIME"
    # if there are ids
    for id in ${ids[@]}; do
        # substitute "@zfsbak_" into "\t"
        zfs_list "$dataset" "$id" | sed 's/@zfsbak_/\t/'
    done
    # if there's no id
    if [ ${#ids[@]} -eq 0 ]; then
        zfs_list "$dataset" "" | sed 's/@zfsbak_/\t/'
    fi
}

function zfsbak_create() {
    dataset="$1"
    rotation=12
    if [ -n "$2" ]; then
        rotation=$2
    fi
    zfs_snap "${dataset}@zfsbak_$(datetime)"
    # check if total number of datasets is over rotation limit
    for snap in $(zfs_list "$dataset" | awk '{ print $2 }' | tail -r | tail -n "+$((rotation+1))" | tail -r); do
        zfs_destroy "$snap"
    done
}

function zfsbak_delete() {
    parse_dataset_id "$@"
    snaps=()
    # if there are ids
    for id in ${ids[@]}; do
        snaps+=($(zfs_list "$dataset" "$id" | awk '{ print $2 }'))
    done
    for snap in ${snaps[@]}; do
        zfs_destroy "$snap"
    done
    # if there's no id
    if [ ${#ids[@]} -eq 0 ]; then
        for snap in $(zfs_list "$dataset" "" | awk '{ print $2 }'); do
            zfs_destroy "$snap"
        done
    fi
}

function zfsbak_export() {
    if [ -n "$1" ]; then
        dataset="$1"
    else
        echo "Dataset is required." >&2
        exit 1
    fi
    id=1
    if [ -n "$2" ]; then
        id="$2"
    fi
    snapname="$(zfs_list "$dataset" "$id" | awk '{ print $2 }')"
    # user's/home/directory/snapname.zst.aes
    pathname="$(getent passwd "$SUDO_USER" | cut -d: -f6)/${snapname/\//_}.zst.aes"
    export EXPORT_PASS=$ZFSBAK_PASS
    zfs send "$snapname" | zstd -qc - | openssl enc -aes-256-cbc -pbkdf2 -pass "env:EXPORT_PASS" -out "$pathname"
    echo "Export $snapname to $pathname"
}

function zfsbak_import() {
    filename="${1?'filename'}"
    dataset="${2?'dataset'}"
    # cp "$filename" /tmp
    echo "Import $filename to $dataset"
    zstd -qcd "$filename" | zfs receive "$dataset@$(datetime)"
}

case "$1" in
    -l|--list)   shift; zfsbak_list   "$@" ;;
    -d|--delete) shift; zfsbak_delete "$@" ;;
    -e|--export) shift; zfsbak_export "$@" ;;
    -i|--import) shift; zfsbak_import "$@" ;;
    *)
        if [ $# == 0 ]; then
            help
        else
            zfsbak_create "$@"
        fi
        ;;
esac