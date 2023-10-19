#!/bin/sh

# Define the help message
help_message="\
hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]

Available Options:

-i: Input file to be decoded
-o: Output directory
-c csv|tsv: Output files.[ct]sv
-j: Output info.json"

# echo help message if less than 4 arguments passed
# $# -> number of arguments passed
if [ $# -lt 4 ]; then
    >&2 echo "$help_message"
    exit 255
fi

# Parse command-line options
# getopts i:o:c:j -> expect command options of i, o, c, j 
# (: means that option expects an argument)
# op -> the current option being processed
# 2>/dev/null -> directs standard error (fd2) to null, so no default error mesg
while getopts i:o:c:j op 2>/dev/null; do
    case $op in
        i)
        # Set the input file
            if [ ! "$OPTARG" ]; then
                >&2 echo "$help_message"
                exit 255
            fi
            input=$OPTARG
            ;;
        o)
        # Set the output directory
            if [ ! "$OPTARG" ]; then
                >&2 echo "$help_message"
                exit 255
            fi
            output=$OPTARG
            ;;
        c)
        # slice_type = csv or tsv
            slice_type=$OPTARG
            ;;
        j)
        # Enable output of info.json
            infojson=1
            ;;
        *)
            # Output help message for invalid options
            # >&2 -> redirects the echo output to stderr and stdout
            >&2 echo "$help_message"
            exit 255
    esac
done

# if input doesn't end with .hw2 then echo help message
if [ "${input%\.hw2}.hw2" != "$input" ]; then
    >&2 echo "$help_message"
    exit 255
fi
 
# if output directory doesn't exist, make it
# -e -> exists
if [ ! -e "$output" ]; then
    # -p -> if the paren't directory doesn't exist in dir/subdir, make dir first then subdir
    mkdir -p "$output"
fi

# if infojson is true then put the name, author, and date into file.json
if [ "$infojson" = "1" ]; then
    name=$(yq '.name' "$input")
    author=$(yq '.author' "$input")
    date=$(yq '.date' "$input")
    date=$(date -r "$date" -Iseconds)
    # extract info into info.json
    printf "{\\n\\t\"name\": %s,\\n\\t\"author\": %s,\\n\\t\"date\": \"%s\"\\n}" "$name" "$author" "$date" > "$output/info.json"
fi

# if -c then put the file header into files.tsv/csv
if [ "$slice_type" = "csv" ]; then
    printf "filename,size,md5,sha1\n" > "$output/files.csv"
elif [ "$slice_type" = "tsv" ]; then 
    printf "filename\tsize\tmd5\tsha1\n" > "$output/files.tsv"
fi

# remember to use '' and not "" because it fucks up the "sha-1"
# parse through the yaml file using yq and extract data
invalid_files=0
invalid_files=$(
    yq -r '.files[] | .name + " " + .type + " " + .data + " " + .hash.md5 + " " + .hash.["sha-1"]' "$input" | 
    while IFS= read -r info; do
        # separate info using awk 
        name=$(echo "$info" | awk '{print $1}')
        # type=$(echo "$info" | awk '{print $2}')
        data=$(echo "$info" | awk '{print $3}')
        md5=$(echo "$info" | awk '{print $4}')
        sha1=$(echo "$info" | awk '{print $5}')
        data_decoded=$(echo "$data" | base64 -d)

        # check data's size
        # it's always less by 1 for some reason so add it back
        size=${#data_decoded}
        size=$((size + 1))

        # put decoded data into the right folder/file
        file_path="$output/$name"
        mkdir -p "$(dirname "$file_path")"
        printf "%s\n" "$data_decoded" > "$file_path"

        # take care of csv/tsv file if needed
        if [ "$slice_type" = "csv" ]; then
            printf "%s,%s,%s,%s\n" "$name" "$size" "$md5" "$sha1" >> "$output/files.csv"
        elif [ "$slice_type" = "tsv" ]; then
            printf "%s\t%s\t%s\t%s\n" "$name" "$size" "$md5" "$sha1" >> "$output/files.tsv"
        fi

        # take care of checksum

        if [ "$md5" != "$(md5sum "$file_path")" ] || [ "$sha1" != "$(sha1sum "$file_path")" ]; then
            invalid_files=$((invalid_files + 1))
            # echo $invalid_files
            # echo $file_path
        fi
    done
)

echo "$invalid_files"
exit $invalid_files