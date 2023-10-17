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
        # Set the output format (csv or tsv)
            slice_type=$OPTARG
            if [ "$slice_type" = "csv" ]; then 
                slice=',' 
            fi
            if [ "$slice_type" = "tsv" ]; then 
                slice=$'\t'
            fi
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

if [ "${input%\.hw2}.hw2" != "$input" ]; then
    >&2 echo "$help_message"
fi