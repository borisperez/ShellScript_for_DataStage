while true
do
ps -ef | grep "DSD.RUN" | grep -v grep | wc -l | awk '{ print "scxx010cau= "$0 }'
rsh scxx011cau "ps -ef" | grep osh | grep -v grep | wc -l | awk '{ print "scxx011cau= "$0 }'
rsh scxx012cau "ps -ef" | grep osh | grep -v grep | wc -l | awk '{ print "scxx012cau= "$0 }'
rsh scxx013cau "ps -ef" | grep osh | grep -v grep | wc -l | awk '{ print "scxx013cau= "$0 }'
sleep 5
echo "**************************"
done