#!/bin/bash
### VARIABLES ###
script_name="scan_public_html.sh"
start_time=$(date +%s)
directory_to_search="public_html"
time_threshold=0.25  # = 15 sec
server_ip=$(curl -s ifconfig.me | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
hostname=$(hostname)
emails_path="emails.txt"
mapfile -t recipient_email < <(grep -Ev "^$" "$emails_path")
full_path=$(find /home/*/public_html -type d -name "$directory_to_search" 2> /dev/null) 
temp_file=$(mktemp)
###-----------###



##########################EXCLUDE##############################

exclusions_path="exclude.txt"
mapfile -t exclusions < <(grep -Ev "^$" "$exclusions_path")
exclusion_patterns=""
for exclusion in "${exclusions[@]}"; do
    exclusion_patterns+=" -not -path $exclusion "
done

#################### SEARCHING FILES ##########################

for path in $full_path; do
  find "$path"  -depth -type f -mmin -$time_threshold $exclusion_patterns   >> "$temp_file" 
done

#################### FILTER OUT ##############################

grep -E -v 'error_log$|/debug/.*\.txt$|/qr/.*\.png$' "$temp_file" > "$temp_file.filtered"


end_time=$(date +%s)
elapsed_time=$((end_time - start_time)) 
if [[ -s "$temp_file.filtered" ]]; then
  echo "Script Runtime $elapsed_time" >> "$temp_file.filtered"
  cat "$temp_file.filtered"
  for email in "${recipient_email[@]}";do
         mail -s "$script_name report,[$server_ip] [$hostname]" "$email" < "$temp_file.filtered" 2> /dev/null
   done
else
  echo "No results!"   
fi

rm "$temp_file" "$temp_file.filtered"


if (! crontab -l | grep "for i in {1..6}; do /time_scan/scan_public_html.sh & sleep 10; done") > /dev/null; then
  cron_entry="* * * * * for i in {1..6}; do /time_scan/scan_public_html.sh & sleep 10; done"
  (crontab -l 2>/dev/null; echo "$cron_entry" ) | crontab -
  sudo systemctl restart crond
  echo "cronjob added"
fi