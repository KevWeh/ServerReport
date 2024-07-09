#!/bin/bash

##########################################################################################

# Script Name   :   serverreport
# Description   :   Script for monitoring critical system parameters on CAPLIVE CH Server
# Args          :   -
# Author        :   Kevin Wehrli
# Email         :   kevin.wehrli@emilfrey.ch

##########################################################################################

clear

# Functions:
#   Function to add an empty line to the output file:
    empty() {
        echo "" >> $file
    }
#   Function to add a separator line to the output file:
    spacer() {
        echo "##########################################################" >> $file
        echo " " >> $file
    }
#   Function to get the percentage of current memory utilisation:
    storage() {
        df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
    }

# Variables:
    DATES=$(date +%d.%m.%y)             # Current date in dd.mm.yy format
    TIME=$(date +%H:%M)                 # Current time in HH:MM format
    file=/tmp/serverreport_$DATES.log   # Path where the output is saved
    server="CAPLIVE"                    # Server name
    countr="CH"                         # Country code
    usage=$(storage)                    # Memory utilisation percentage
    logfilepath=/var/log/asc/           # Log file path

#   Web services and log file names:
    asc="ascserver"
    autoi="${asc}_autoi"
    fordpr="${asc}_fordproxy"
    pl59="${asc}_pl5959"
    pl65="${asc}_pl6565"
    pl69="${asc}_pl6969"
    pl70="${asc}_pl7070"
    ascw="ascwatchdog"

#   Initial status values:
    webservice_status="OK"
    webservice_error="" 
    logcounter_status="OK"
    logcounter_error=""
    logsize_status="OK"
    logsize_error=""

# Arrays of web services and log files:
    webservices=(${asc} ${autoi} ${fordpr} ${pl59} ${pl65} ${pl69} ${pl70} ${ascw})
    logs=("${asc}.log*" "${autoi}*.log" "${fordpr}*.log" "${pl59}*.log" "${pl65}*.log" "${pl69}*.log" "${pl70}*.log" "${ascw}*.log")

# Create the log file:
echo " " > $file

# Add the title to the log file:
cat <<TITLE >> $file
##########################################################
#   ________   ___  __   _____   ______       _______ __ #
#  / ___/ _ | / _ \/ /  /  _/ | / / __/____  / ___/ // / #
# / /__/ __ |/ ___/ /___/ / | |/ / _/ /___/ / /__/ _  /  #
# \___/_/ |_/_/  /____/___/ |___/___/       \___/_//_/   #
#                                                        #
##########################################################
TITLE

empty

# Add the current date and time to the log file:
echo "                     $DATES - $TIME" >> $file

empty

# Check memory utilisation and add the result to the log file:
if [ "$usage" -lt 60 ]; then
    echo "       Speicherplatz:.................... $usage% | OK" >> $file
elif [ "$usage" -ge 60 ] && [ "$usage" -le 80 ]; then
    echo "       Speicherplatz:.................$usage% | CHECK!" >> $file
else
    echo "       Speicherplatz:..............$usage% | CRITICAL!" >> $file
fi

# Check the status of each web service and add the results to the log file:
for ws in "${webservices[@]}"; do
    status=$(systemctl is-active "$ws")
    if [ "$status" != "active" ]; then
        webservice_status="ERROR"
        webservice_error="${webservice_error}$(printf "       | %-19s................!DOWN!" "$ws")\n"   
    fi
done

if [ "$webservice_status" == "OK" ]; then
    echo "       Webservices:.............................OK" >> $file
else
    echo "       Webservices:..........................ERROR" >> $file
    echo -e "$webservice_error" >> $file
fi

# Check the number of log files and add the results to the log file:
for logct in "${logs[@]}"; do
    counter=$(find $logfilepath -name "$logct" | wc -l)
    if [ "$counter" -gt "10" ]; then
        logcounter_status="ERROR"
        logcounter_error="${logcounter_error}$(printf "       | %-22s...........$counter Files" "$logct")\n" 
    fi
done

if [ "$logcounter_status" == "OK" ]; then
    echo "       Anzahl Logfiles:.........................OK" >> $file
else
    echo "       Anzahl Logfiles:......................ERROR" >> $file
    echo -e "$logcounter_error" >> $file
fi

# Check the size of each log file and add the results to the log file:
for sizelogs in "${logs[@]}"; do
    for logfile in $logfilepath$sizelogs; do
        if [ -e "$logfile" ]; then
            logsize=$(stat -c %s "$logfile" 2>/dev/null)
            logsize_h=$(du -h "$logfile" 2>/dev/null | awk '{print $1}')

            if [ "$logsize" -gt 10485760 ]; then
                logsize_status="ERROR"
                logsize_error="${logsize_error}$(printf "       | %-32s......$logsize_h" "$(basename "$logfile")")\n"
            fi
        fi
    done
done

if [ "$logsize_status" == "OK" ]; then
    echo "       Groesse Logfiles:........................OK" >> $file
else
    echo "       Groesse Logfiles:.....................ERROR" >> $file
    echo -e "$logsize_error" >> $file
fi

# Display the contents of the log file:
cat $file

sync

# Send an email if there is any error:
mail_content=$(cat $file)
html_content="<html><body><pre style=\"font-family: 'Lucida Console', 'Consolas', 'Courier New', monospace;\">$mail_content</pre></body></html>"

if [ "$usage" -ge 60 ] || [ "$webservice_status" == "ERROR" ] || [ "$logcounter_status" == "ERROR" ] || [ "$logsize_status" == "ERROR" ]; then
    echo -e "Subject: $server-$countr - ERROR\nContent-Type: text/html\n\n$html_content" | msmtp -a default kevin.wehrli@emilfrey.ch
    echo ""
    echo "                          ERROR"
    echo ""
else
    echo ""
    echo "                        System OK"
    echo ""
fi
echo "##########################################################"