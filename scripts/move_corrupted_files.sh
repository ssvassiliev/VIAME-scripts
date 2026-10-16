#!/bin/bash
# Usage: ./move_corrupted_files.sh <list_of_files.txt> <destination_dir>

LIST_FILE="$1"
DEST_DIR="$2"

if [[ -z "$LIST_FILE" || -z "$DEST_DIR" ]]; then
    echo "Usage: $0 <list.txt> <destination_dir>"
    exit 1
fi

mkdir -p "$DEST_DIR"

count=0
missing=0

while IFS= read -r filepath; do
    # skip blank lines
    [[ -z "$filepath" ]] && continue

    if [[ -f "$filepath" ]]; then
        mv -v -- "$filepath" "$DEST_DIR/"
        ((count++))
    else
        echo "MISSING (not found): $filepath"
        ((missing++))
    fi
done < "$LIST_FILE"

echo "----"
echo "Moved: $count file(s)"
echo "Missing: $missing file(s)"
