#!/bin/bash
directory_to_search="public_html"
time_threshold=0.25  # quarter min = 15 sec

emails_path="emails.txt"
mapfile -t recipient_email < <(grep -Ev "^$" "$emails_path")

full_path=($(find /home -type d -name "$directory_to_search" 2> /dev/null)) 
temp_file=$(mktemp)

for path in "${full_path[@]}"; do
 find "$path" -depth -type f -cmin -$time_threshold 2> /dev/null >> "$temp_file"  
done

if [[ -s "$temp_file" ]]; then 
  mail -s "Files Created Last 10sec" "${recipient_email[@]}" < "$temp_file" 
fi

rm "$temp_file"