#!/bin/sh
# shellcheck disable=SC3003

# Define the help message
help="\
hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]

Available Options:

-i: Input file to be decoded
-o: Output directory
-c csv|tsv: Output files.[ct]sv
-j: Output info.json"

# Parse command-line options
while getopts i:o:c:j op 2>/dev/null; do
  case $op in
    i)
      # Set the input file
      input=$OPTARG
      ;;
    o)
      # Set the output directory
      output=$OPTARG
      ;;
    c)
      # Set the output format (csv or tsv)
      XSV=$OPTARG
      if [ "$XSV" = "tsv" ]; then XSVSPL=$'\t'; fi
      if [ "$XSV" = "csv" ]; then XSVSPL=','; fi
      ;;
    j)
      # Enable output of info.json
      infojson=1
      ;;
    *)
      # Output help message for invalid options
      >&2 echo "$help"
      exit 255
  esac
done

# Check if the input file ends with .hw2
if [ ! "${input}" ] || [ "${input}" != "${input%\.hw2}.hw2" ] && false; then
  >&2 echo "Input file must end with .hw2 ($input)"
  >&2 echo "$help"
  exit 255
fi

# Create the output directory if it doesn't exist
mkdir -p "${output}"
if [ ! "${output}" ] || [ ! -d "${output}" ]; then
  >&2 echo "Output not directory ($output)"
  >&2 echo "$help"
  exit 255
fi

# If info.json output is enabled, extract name, author, and date from the input file and write to info.json
if [ "$infojson" ]; then
  name=$(jq -r '.name' "${input}")
  author=$(jq -r '.author' "${input}")
  date=$(jq -r '.date' "${input}")
  date=$(date -r "$date" -Iseconds)
  jq -r -n "{\"name\":\"$name\",\"author\":\"$author\",\"date\":\"$date\"}"  > "$output/info.json"
fi

# If csv or tsv output is enabled, write the file header to files.[ct]sv
if [ "$XSVSPL" ]; then
  echo "filename${XSVSPL}size${XSVSPL}md5${XSVSPL}sha1" > "$output/files.$XSV"
fi

# Process each file in the input file
error_files=$(
  jq -r '.files[] | [.name, .type, .data, .hash.md5, .hash["sha-1"]] | @tsv' "${input}" |
    while IFS=$'\t' read -r fn _ data md5 sha1; do
      f="$output/$fn"
      mkdir -p "$(dirname "$f")"
      size=$(echo "$data" | base64 -d | tee "$f" | wc -c | tr -d ' ')

      # If csv or tsv output is enabled, write the file info to files.[ct]sv
      if [ "$XSVSPL" ]; then
        echo "$fn${XSVSPL}$size${XSVSPL}$md5${XSVSPL}$sha1" >> "$output/files.$XSV"
      fi

      # Check if the file's md5 and sha1 hashes match the expected values
      if [ "$md5" != "$(md5sum -q "$f")" ] || [ "$sha1" != "$(sha1sum -q "$f")" ]; then
        # rm "$f"
        error_files=$((error_files+1))
        echo "$f"
      fi
    done |
  wc -l
)

# Exit with the number of files that had errors
exit $error_files