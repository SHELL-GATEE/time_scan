#!/bin/bash
start_time=$(date +%s)
directory_to_search="public_html"
time_threshold=300.25  # quarter min = 15 sec

emails_path="emails.txt"
mapfile -t recipient_email < <(grep -Ev "^$" "$emails_path")


full_path=($(find /home -maxdepth 2 -type d -name "$directory_to_search" 2> /dev/null)) 

temp_file=$(mktemp)


##########################EXCLUDE##############################
exclusions_path="exclude.txt"
mapfile -t exclusions < <(grep -Ev "^$" "$exclusions_path")
exclusion_patterns=""
for exclusion in "${exclusions[@]}"; do
    exclusion_patterns+=" -not -path $exclusion "
done
###############################################################


for path in "${full_path[@]}"; do
  find "$path"  -depth -type f -mmin -$time_threshold $exclusion_patterns   >> "$temp_file" 
done



#################### FILTER OUT ##############################
grep -v 'error_log$' "$temp_file" > "$temp_file.filtered1" 
grep -v '/debug/.*\.txt$' "$temp_file.filtered1" > "$temp_file.filtered"
##############################################################

cat "$temp_file.filtered"

end_time=$(date +%s)
elapsed_time=$((end_time - start_time)) 
if [[ -s "$temp_file.filtered" ]]; then 
  mail -s "Files Created Last 10sec, Runtime ($elapsed_time secondes)" "${recipient_email[@]}" < "$temp_file.filtered"
else
  echo No results!   
fi

rm "$temp_file" "$temp_file.filtered" "$temp_file.filtered1"