
for i in `dsjob -lprojects`
do
  PurgeEnabled=`grep PurgeEnabled /IS/Projects/$i/DSParams 2>/dev/null ` 
  DaysOld=`grep DaysOld /IS/Projects/$i/DSParams 2>/dev/null`
  PrevRuns=`grep PrevRuns /IS/Projects/$i/DSParams 2>/dev/null`
  echo $i"-"$PurgeEnabled"-"$DaysOld"-"$PrevRuns
done
