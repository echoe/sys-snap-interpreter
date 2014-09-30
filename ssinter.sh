#!/bin/bash
#sys-snap interpreter, written for cPanel's version
#https://github.com/echoe/sys-snap-interpreter/
#Version 0.14

function checkload
{
        top=`head -n1 $1`;
        thetime=`echo $top | awk '{print $2,$3}'`
        load1min=`echo $top | awk '{print $6}' |cut -d. -f1`
        load5min=`echo $top | awk '{print $7}' |cut -d. -f1`
        load10min=`echo $top | awk '{print $8}' |cut -d. -f1`
        if [ $load1min -gt 5 ] || [ $load5min -gt 5 ] || [ $load10min -gt 5 ]; then
                echo $top;
        fi
}

function checkmem
{
        memory=`sed -n '/Memory Usage:/,/Virtual Memory Stats:/p' $1 | head -n -2 | tail -n +3`
        memfree=`echo $memory | grep MemFree | awk '{print $2}'`
        swapfree=`echo $memory | grep SwapFree | awk '{print $2}'`
        if [ $memfree -lt 50000 ] || [ $swapfree -lt 5000 ] ; then 
                echo $thetime "Free Memory" $memfree "Swap" $swapfree; 
        fi
}

function checkvirtmem 
{
        virtualmemory=`sed -n '/Virtual Memory Stats:/,/Process List:/p' $1 | head -n -2 | tail -n +5`
        waittime=`echo $virtualmemory | rev | awk '{print $2}' | rev`
        waitissues="n"; 
        for i in $waittime; do 
                if [ $i > 10 ] ; then 
                        waitissues="y"; 
                fi; 
        done
        if [ waitissues == y ]; then
                echo "wait issues at log" $thetime;
        fi
}

function checkps 
{
        processcpu=`sed -n '/Process List:/,/Network Connections:/p' $1 | head -n -2 | tail -n +4 | sort -nrk 3 | head -n2`
        echo $processcpu | while read ; do
                line=$REPLY ;
                if [ `echo $line | awk '{print $3}' | cut -d. -f1` -gt 100 ] ; then
                        echo "Time" $thetime "Cpu over 100";
                fi;
        done;
}

function checknetwork 
{
        networklist=`sed -n '/Active Internet connections/,/Active UNIX domain sockets/p' $1 | head -n -1 | tail -n +3`
        networknum=`echo $networklist | wc -l`
        networkips=`echo $networklist | awk '{print $5}' | sort | uniq -c | head -n 5`
        if [[ $networknum -gt 100 ]] ; then
                echo "Time" $thetime "Number of httpd connections" $networknum "exploiting IPs" $networkips;
        fi
}

function checkmysql 
{
        mysqllist=`sed -n '/MYSQL Processes:/,/Apache Processes:/p' $1 | head -n -2 | tail -n +3`
        mysqlnum=`echo $mysqllist | wc -l`
        if [[ $mysqlnum -gt 20 ]] ; then
                echo "Date" $thetime "Number of mysql connections" $mysqlnum;
        fi
}

function checkapache 
{
        apachelist=`sed -n '/Apache Processes:/,/Network Connections:/p' $1 | head -n -2 | tail -n +3`
        apachenum=`echo $apachelist | wc -l`
        if [[ $apachenum -gt 100 ]] ; then
                echo "Date" $thetime "Number of httpd connections" $apachenum;
        fi
}

echo "Checking now. This may take a little while to finish."
for logfile in $(/bin/ls -A /root/system-snapshot/*/*.log); do
        checkload $logfile
        checkmem $logfile
        checkvirtmem $logfile
        checkps $logfile
        checknetwork $logfile
        checkmysql $logfile
        checkapache $logfile
done
echo "Finished!"
