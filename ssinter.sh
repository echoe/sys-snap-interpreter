#!/bin/bash
#sys-snap interpreter, written for cPanel's version
#Version 0.22

#If you don't know what you're doing, you can edit values here!

#This by default grabs the server limit and finds anything 6 times larger than it, which is an approximate guess(??) as to when this would cause an issue.
#The apache and network checks are currently in search of good approximate values to check by.
networkdefault=$((`grep ServerLimit /etc/httpd/conf/httpd.conf | awk '{print $2}'` * 6))

#Loadbound: Amount of load that's OK before the script alerts. (This actually tests for 6 and higher.)
loadbound=5
#Membound: Amount of memory free before the script alerts. This is a higher bound (i.e. 40k memory free alerts it).
membound=50000
#Swapbound: Amount of memory free before the script alerts. This is a higher bound (i.e. no swap free alerts it).
swapbound=5000
#Waitbound: Percentage of waittime before the script alerts. This is a lower bound (i.e. anything over 10 alerts it).
waitbound=10
#CPUbound: Percentage of CPU used by single process before the script alerts. This is a lower bound (i.e. anything over 100% alerts it).
cpubound=100
#Networkbound: amount of network connections before the script alerts. This is a lower bound (anything above 100 alerts it).
networkbound=$networkdefault
#Diskbound: amount of % that a dis has to be full before this script warns about it. This is a lower bound (anything above 85 alerts it).
diskbound=85
#MySQLbound: amount of MySQL connections before the script alerts. This is a lower bound (anything above 20 alerts it).
mysqlbound=20
#Apachebound: amount of apache connections before the script alerts. This is a lower bound (anything above 100 alerts it).
apachebound=$networkdefault

#As syssnap says: "If you don't know what your doing, don't edit anything below this line"

function checkload
{
        top=`head -n1 $1`;
        thetime=`echo $top | awk '{print $2,$3}'`
        load1min=`echo $top | awk '{print $6}' |cut -d. -f1`
        load5min=`echo $top | awk '{print $7}' |cut -d. -f1`
        load10min=`echo $top | awk '{print $8}' |cut -d. -f1`
        if [ $load1min -gt $loadbound ] || [ $load5min -gt $loadbound ] || [ $load10min -gt $loadbound ]; then
                echo "Load issues:" $top;
        fi
}

function checkmem
{
        memory=`sed -n '/Memory Usage:/,/Virtual Memory Stats:/p' $1 | head -n -2 | tail -n +3`
        memfree=`echo $memory | grep MemFree | awk '{print $2}'`
        swapfree=`echo $memory | grep SwapFree | awk '{print $2}'`
        if [ $memfree -lt $membound ] || [ $swapfree -lt $swapbound ] ; then
                echo $thetime "Free Memory: " $memfree "Swap: " $swapfree;
        fi
}

function checkvirtmem
{
        virtualmemory=`sed -n '/Virtual Memory Stats:/,/Process List:/p' $1 | head -n -2 | tail -n +5`
        waittime=`echo $virtualmemory | rev | awk '{print $2}' | rev`
        waitissues="n";
        for i in $waittime; do
                if [ $i > $waitbound ] ; then
                        waitissues="y";
                fi;
        done
        if [ waitissues == y ]; then
                echo "Wait issues at log at time: " $thetime;
        fi
}

function checkps
{
        processcpu=`sed -n '/Process List:/,/Network Connections:/p' $1 | head -n -2 | tail -n +4 | sort -nrk 3 | head -n2`
        echo $processcpu | while read ; do
                line=$REPLY ;
                if [[ `echo $line | awk '{print $3}' | cut -d. -f1` -gt $cpubound ]] ; then
                        echo "Time: " $thetime "Cpu over: " $cpubound;
                fi;
        done;
}

function checknetwork
{
        networknum=`sed -n '/Active Internet connections/,/Active UNIX domain sockets/p' $1 | head -n -1 | tail -n +3 | wc -l`
        networkips=`sed -n '/Active Internet connections/,/Active UNIX domain sockets/p' $1 | head -n -1 | tail -n +3 | grep :80 | awk '{print $4}' | sort | uniq -c | sort -nrk 1 | head -n 2`
        if [[ $networknum -gt $networkbound ]] ; then
                echo "Time: " $thetime "Number of total httpd connections: " $networknum "Largest # of IPs: " $networkips;
        fi
}

function checkdisk
{
        diskspace=`sed -n '/Disk Space Usage:/,/MYSQL Processes:/p' $1 | head -n -2 | tail -n +4 | sort -nrk 5 | head -n1`
        if [[ `echo $diskspace | awk '{print $5}' | cut -d% -f1` -gt $diskbound ]]; then
                echo "Time: " $thetime "Line: " $diskspace
        fi
}

function checkmysql
{
        mysqlnum=`sed -n '/MYSQL Processes:/,/Apache Processes:/p' $1 | head -n -2 | tail -n +3 | wc -l`
        if [[ $mysqlnum -gt $mysqlbound ]] ; then
                echo "Time: " $thetime "Number of mysql connections: " $mysqlnum;
        fi
}

function checkapache
{
        apachenum=`sed -n '/Apache Processes:/,/Network Connections:/p' $1 | head -n -2 | tail -n +3 | grep -E ':80|:443' | grep -v "GET / HTTP" | grep -v "127.0.0.1" | grep -v status | wc -l`
        if [[ $apachenum -gt $apachebound ]] ; then
                echo "Time: " $thetime "Number of httpd connections: " $apachenum;
        fi
}

echo "Checking now. This may take a little while to finish."
echo "If you get too many or too few results, please manually edit the options in the script."

for logfile in $(/bin/ls -A /root/system-snapshot/*/*.log); do
        checkload $logfile
        checkmem $logfile
        checkvirtmem $logfile
        checkps $logfile
        checknetwork $logfile
        checkdisk $logfile
        checkmysql $logfile
        checkapache $logfile
done

echo "Finished!"
