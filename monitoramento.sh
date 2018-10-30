/software/IS/Engine/Server/DSEngine/bin/adm/verifica_ambiente.sh > rep_temp_monit
n=`cat rep_temp_monit | egrep -c 'rsh issued, no response received|FAILED|Unable to contact one or more Section Leaders|Not running'`
rm -f rep_temp_monit
return $n


