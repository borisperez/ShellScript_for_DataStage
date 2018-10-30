rm -f .logsize
for i in `dsjob -lprojects`
do
  for y in `ls -l /IS/Projects/$i/RT_LOG* | grep ^\/ | awk -F":" '{ print $1}' 2>/dev/null`
  do
    du -m $y >> .bodylogsize
  done
done
  sort -k1n .bodylogsize >> .logsize
  rm -f *.bodylogsize
  cat .logsize
