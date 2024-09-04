# time_scan


# to run as a cronjob every 10 sec
```bash
* * * * * for i in {1..6}; do /time_scan/scan_public_html.sh & sleep 10; done
```
