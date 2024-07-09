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
#   Empty line:
    empty() {
        echo "" >> $file
    }
#   Spacer:
    spacer() {
        echo "##########################################################" >> $file
        echo " " >> $file
    }
#   Read out % of the current memory utilisation:
    storage() {
        df -h / | awk 'NR==2 {print $5}' | sed 's/%//'
    }

# Variables:
#   Time + Date:
    DATES=$(date +%d.%m.%y)
    TIME=$(date +%H:%M)
#   Path where output is saved:
    file=/tmp/serverreport_$DATES.log
#   Serverinfo:
    server="CAPLIVE"
    countr="CH"
#   Memory utilisation
    usage=$(storage)
#   Webservices + Logfiles:
    asc="ascserver"
    autoi="${asc}_autoi"
    fordpr="${asc}_fordproxy"
    pl59="${asc}_pl5959"
    pl65="${asc}_pl6565"
    pl69="${asc}_pl6969"
    pl70="${asc}_pl7070"
    ascw="ascwatchdog"
#   Webservice Status:
    ws_stat="OK"
    ws_err=""
#   Logpath:
    lopa=/var/log/asc/
#   Logfiles Status:
    logct_stat="OK"
    logct_err=""
    logsi_stat="OK"
    logsi_err=""

# Arrays:
#   Webservices:
    webservices=(${asc} ${autoi} ${fordpr} ${pl59} ${pl65} ${pl69} ${pl70} ${ascw})
#   Logfiles:
    logs=("${asc}.log*" "${autoi}*.log" "${fordpr}*.log" "${pl59}*.log" "${pl65}*.log" "${pl69}*.log" "${pl70}*.log" "${ascw}*.log")

# Creat logfile:
echo " " > $file

# Titel:
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

echo "                     $DATES - $TIME" >> $file

empty

# Storage (df -h /):
if [ "$usage" -lt 60 ]; then
    echo "       Speicherplatz:.................... $usage% | OK" >> $file
elif [ "$usage" -ge 60 ] && [ "$usage" -le 80 ]; then
    echo "       Speicherplatz:.................$usage% | CHECK!" >> $file
else
    echo "       Speicherplatz:..............$usage% | CRITICAL!" >> $file
fi

# Webservices:
for ws in "${webservices[@]}"; do
    status=$(systemctl is-active "$ws")
    if [ "$status" != "active" ]; then
        ws_stat="ERROR"
        ws_err="${ws_err}$(printf "       | %-19s................!DOWN!" "$ws")\n"   
    fi
done

if [ "$ws_stat" == "OK" ]; then
    echo "       Webservices:.............................OK" >> $file
else
    echo "       Webservices:..........................ERROR" >> $file
    echo -e "$ws_err" >> $file
fi

# Counter Logfiles:
for logct in "${logs[@]}"; do
    counter=$(find $lopa -name "$logct" | wc -l)
    if [ "$counter" -gt "10" ]; then
        logct_stat="ERROR"
        logct_err="${logct_err}$(printf "       | %-22s...........$counter Files" "$logct")\n" 
    fi
done

if [ "$logct_stat" == "OK" ]; then
    echo "       Anzahl Logfiles:.........................OK" >> $file
else
    echo "       Anzahl Logfiles:......................ERROR" >> $file
    echo -e "$logct_err" >> $file
fi

# Logfiles size:
for sizelogs in "${logs[@]}"; do
    for logfile in $lopa$sizelogs; do
        if [ -e "$logfile" ]; then
            logsize=$(stat -c %s "$logfile" 2>/dev/null)
            logsize_h=$(du -h "$logfile" 2>/dev/null | awk '{print $1}')

            if [ "$logsize" -gt 10485760 ]; then
                logsi_stat="ERROR"
                logsi_err="${logsi_err}$(printf "       | %-32s......$logsize_h" "$(basename "$logfile")")\n"
            fi
        fi
    done
done

if [ "$logsi_stat" == "OK" ]; then
    echo "       Groesse Logfiles:........................OK" >> $file
else
    echo "       Groesse Logfiles:.....................ERROR" >> $file
    echo -e "$logsi_err" >> $file
fi

cat $file

sync

# Send email in case of an ERROR:
mail_content=$(cat $file)
html_content="<html><body><pre style=\"font-family: 'Lucida Console', 'Consolas', 'Courier New', monospace;\">$mail_content</pre></body></html>"

if [ "$usage" -ge 60 ] || [ "$ws_stat" == "ERROR" ] || [ "$logct_stat" == "ERROR" ] || [ "$logsi_stat" == "ERROR" ]; then
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