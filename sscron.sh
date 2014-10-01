#This installs a sys-snap cronjob and runs recordkeeping to keep sys-snap [and this script!] up to date.
#To run this: bash <(curl https://raw.githubusercontent.com/echoe/sys-snap-interpreter/master/sscron.sh)
#Version 0.01
ps aux | awk '/[s]ys-snap/ {print$2}' | xargs kill
if [[ -z `/bin/ls -A /root/sys-snap.pl` ]] ; then
        su - -c "wget -N -P /root https://raw.githubusercontent.com/cPanelTechs/SysSnap/master/sys-snap.pl"
fi
perl /root/sys-snap.pl 2>/dev/null &
if [[ -z `crontab -l | grep "sscron.sh"` ]]; then
    crontab -l > /tmp/mycrontab.txt;
    echo "0 0 * * * /bin/sh /root/sscron.sh" >> /tmp/mycrontab.txt;
    crontab /tmp/mycrontab.txt;
    rm -f /tmp/mycrontab.txt
fi
find /root/system-snapshot* -mtime +14 -delete
