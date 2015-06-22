#!/usr/local/python
#sam felshman
#sys-snap interpreter, written for cPanel's version
#Version 0.04

#for grabbing files
import os
#for grabbing directories
import glob
#for sorting strings and grabbing the integer: unneeded if you grab by string and cast to int as we are now but is needed for commented-out option
#import re

#If you don't know what you're doing, you can edit values here!


#This by default grabs the server limit and finds anything 6 times larger than it, which is an approximate guess(??) as to when this would cause an issue.
httpdconf = open('/etc/httpd/conf/httpd.conf', 'r')
for line in httpdconf:
        if "ServerLimit" in line:
                networkdefault = line.split(" ",1)[1]
#loadbound: Amount of load that's OK before the script alerts. (This actually tests for 6 and higher.)
loadbound=5
#Membound: Amount of memory free before the script alerts. This is a higher bound (i.e. 40k memory free alerts it).
membound=70.0
#Swapbound: Amount of memory free before the script alerts. This is a higher bound (i.e. low swap alerts it). 0 by default because of Virtuozzo.
swapbound=0
#Waitbound: Percentage of waittime before the script alerts. This is a lower bound (i.e. anything over 10 alerts it).
waitbound=10
#CPUbound: Percentage of CPU used by single process before the script alerts. This is a lower bound (i.e. anything over 100% alerts it).
cpubound=100.0
#Networkbound: amount of network connections before the script alerts. This is a lower bound.
networkbound = networkdefault
#Diskbound: amount of % that a dis has to be full before this script warns about it. This is a lower bound (anything above 85 alerts it).
diskbound=85
#MySQLbound: amount of MySQL connections before the script alerts. This is a lower bound (anything above 20 alerts it).
mysqlbound=20
#Apachebound: amount of apache connections before the script alerts. This is a lower bound.
apachebound = networkdefault

#As syssnap says: "If you don't know what your doing, don't edit anything below this line"

def checkload(logfile,thetime):
        #if none of this works, "oh, it is different... [5:6] gives a list, [5] gives an element". not sure if casting this as int works but can split it up and it works, e.g. load1min = top.splitetc. , load1min = int(load1min)
        load1min = int(top.split(" ")[5].split(".")[0])
        load5min = int(top.split(" ")[6].split(".")[0])
        load10min = int(top.split(" ")[7].split(".")[0])
        if load1min > loadbound or load5min > loadbound or load10min > loadbound:
                print "Load issues: {0}".format(top)
                print "loadbound {0} load1min {1} load5min {2} load10min {3}".format(loadbound,load1min,load5min,load10min)

def checkmem(logfile,thetime):
        memlog = open(logfile, 'r')
        parsing = False
        for line in memlog:
                if line.startswith("Memory Usage:"):
                        parsing = True
                elif line.startswith("Virtual Memory Stats:"):
                        parsing = False
                if parsing:
                        if line.startswith("MemFree:"):
                                memfree = ''.join(x for x in line if x.isdigit())
                                memfree = int(memfree)
                        if line.startswith("SwapFree:"):
                                swapfree = ''.join(x for x in line if x.isdigit())
                                swapfree = int(swapfree)
#                        if line.startswith("MemFree:"):
#                                memfree = int(re.search(r'\d+', line).group())
#                        if line.startswith("SwapFree:"):
#                                swapfree = int(re.search(r'\d+', line).group())
        if memfree < membound or swapfree < swapbound:
                print "Time: {0} Free Memory: {1} Swap: {2}".format(thetime,memfree,swapfree)
                
#def checkvirtmem(logfile,thetime):
#this is baffling and I will do it last
#       parsing = False
#        for line in memlog:
#                if line.startswith("Virtual Memory Stats:"):
#                        parsing = True
#                elif line.startswith("Process List:"):
#                        parsing = False
#                if parsing:
#                        if line.startswith("MemFree:"):
#                                memfree = ''.join(x for x in line if x.isdigit())
#                                memfree = int(memfree)
#                        if line.startswith("SwapFree:"):
#                                swapfree = ''.join(x for x in line if x.isdigit())
#                                swapfree = int(swapfree)
#        virtualmemory=`sed -n '/Virtual Memory Stats:/,/Process List:/p' $1 | head -n -2 | tail -n +5`
#        waittime=`echo $virtualmemory | rev | awk '{print $2}' | rev`
#        waitissues="n"
#        for i in waittime:
#                if i > waitbound:
#                        waitissues="y";
#        if waitissues == y:
#                echo "Wait issues at log at time: {0}".format(thetime)
#        fi
def checkps(logfile,thetime):
        pslog = open(logfile, 'r')
        firstline = pslog.readline()
        thetime = firstline.split(" ")[1:3]
        parsing = False
        for line in pslog:
                if line.startswith("Process List:"):
                        parsing = True
                elif line.startswith("Network Connections:"):
                        parsing = False
                if parsing:
                        psarray = line.split()
                        if len(psarray) > 4:
                                if psarray[2] != "%CPU":
                                        curcpu = psarray[2]
                                        curmem = psarray[3]
                                        if float(curcpu) > float(cpubound):
                                                print "Time: {0} CPU Usage: {1}".format(thetime,curcpu)
                                        if float(curmem) > float(membound):
                                                print "Time: {0} Memory Usage: {1}".format(thetime,curmem)
                                                
#def checknetwork(logfile,thetime):
#        parsing = False
#        for line in memlog:
#                if line.startswith("Active Internet connections"):
#                        parsing = True
#                elif line.startswith("Active UNIX domain sockets"):
#                        parsing = False
#                if parsing:
#        networknum=`sed -n '/Active Internet connections/,/Active UNIX domain sockets/p' $1 | head -n -1 | tail -n +3 | wc -l`
#        networkips=`sed -n '/Active Internet connections/,/Active UNIX domain sockets/p' $1 | head -n -1 | tail -n +3 | grep :80 | awk '{print $4}' | sort | uniq -c | sort -nrk 1 | head -n 2`
#        if [[ $networknum -gt $networkbound ]] ; then
#                echo "Time: " $thetime "Number of total httpd connections: " $networknum "Largest # of IPs: " $networkips;

#def checkdisk(logfile,thetime):
#        parsing = False
#        for line in memlog:
#                if line.startswith("Disk Space Usage:"):
#                        parsing = True
#                elif line.startswith("MYSQL Processes:"):
#                        parsing = False
#                if parsing:
#                       if line.startswith("MemFree:"):
#                                memfree = ''.join(x for x in line if x.isdigit())
#                                memfree = int(memfree)
#                        if line.startswith("SwapFree:"):
#                                swapfree = ''.join(x for x in line if x.isdigit())
#                                swapfree = int(swapfree)
#       diskspace=`sed -n '/Disk Space Usage:/,/MYSQL Processes:/p' $1 | head -n -2 | tail -n +4 | sort -nrk 5 | head -n1`
#        if [[ `echo $diskspace | awk '{print $5}' | cut -d% -f1` -gt $diskbound ]]; then
#                echo "Time: " $thetime "Line: " $diskspace

def checkmysql(logfile,thetime):
        mysqllog = open(logfile, 'r')
        firstline = mysqllog.readline()
        thetime = firstline.split(" ")[1:3]
        parsing = False
        mysqlnum = 0
        for line in mysqllog:
                if line.startswith("MYSQL Processes:"):
                        parsing = True
                elif line.startswith("Apache Processes:"):
                        parsing = False
                if parsing:
                        mysqlnum = mysqlnum + 1
        if mysqlnum > mysqlbound:
                print "Time: {0} Number of MySQL processes: {1}".format(thetime,mysqlnum)

#def checkapache(logfile,thetime):
#        parsing = False
#        for line in memlog:
#                if line.startswith("Apache Processes:"):
#                        parsing = True
#                elif line.startswith("Network Connections:"):
#                        parsing = False
#                if parsing:
#        apachenum=`sed -n '/Apache Processes:/,/Network Connections:/p' $1 | head -n -2 | tail -n +3 | grep -E ':80|:443' | grep -v "GET / HTTP" | grep -v "127.0.0.1" | grep -v status | wc -l`
#        if [[ $apachenum -gt $apachebound ]] ; then
#                echo "Time: " $thetime "Number of httpd connections: " $apachenum;
#        fi

#the program starts!

print "Checking now. This may take a little while to finish."
print "If you get too many or too few results, please manually edit the options in the script."

logfiles=glob.glob("/root/system-snapshot/*/*.log")

for logfile in logfiles:
        loadlog = open(logfile, 'r')
        top = loadlog.readline()
        thetime = top.split(" ")[1:3]
        checkload(logfile,thetime)
        checkmem(logfile,thetime)
#        checkvirtmem(logfile,thetime)
        checkps(logfile,thetime)
#        checknetwork(logfile,thetime)
#        checkdisk(logfile,thetime)
        checkmysql(logfile,thetime)
#        checkapache(logfile,thetime)

print "Finished!"
