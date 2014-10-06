#This installs a sys-snap cronjob and does maintenance on the 'install'.
#Version 0.10
if [[ ! -e /root/sys-snap.pl ]]; then
        wget -N -P /root/ https://raw.githubusercontent.com/echoe/sys-snap-interpreter/master/sys-snap.pl
fi
if [[ ! -e /root/sscron.sh ]]; then
        wget -N -P /root/ https://raw.githubusercontent.com/echoe/sys-snap-interpreter/master/sscron.sh
fi
if [[ ! -e /etc/cron.d/syssnap ]]; then
    echo "0 0 * * * /bin/sh /usr/local/bin/sscron.sh" > /etc/cron.d/syssnap
fi
ps aux | awk '/[s]ys-snap/ {print$2}' | xargs kill
perl /root/sys-snap.pl 2>/dev/null &
find /root/system-snapshot* -type d -mtime +14 -delete
