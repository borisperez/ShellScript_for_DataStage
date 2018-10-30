rm -f .log

v_data=`date +"%d%m%Y_%H%M"`
v_user=`whoami`


function fn_Clear
{
rm -f .log
}

function fn_CheckDS
{
  for y in `cat .tools`
  do
   fn_RshGet $1 $y
  done
}

function fn_CheckDB2
{
  for y in `cat .tools | grep DB2 `
  do
   fn_RshGet $1 $y 
  done
}

function fn_CheckSAS
{
  for y in `cat .tools | grep SAS ; cat .tools | grep Geral`
  do
   fn_RshGet $1 $y
  done
}

function fn_RshGet
{
errofile=""
errouser=""
errofilespace=""
   v_tipo_tool=`echo $2 | awk -F"|" ' {print $1}'`
   v_tool_home=`echo $2 | awk -F"|" ' {print $2}'`
   cabec=`echo "Conectando... $1 | Check $v_tipo_tool | dir $v_tool_home | QtdFiles="`
   file=`rsh $1 " ls $v_tool_home 2>.errofile | wc -l | tr -d [:space:]"`
   if [ $file -eq 0 ]
    then
     errofile="Erro-File "`rsh $1 "cat .errofile"`
   fi
   if [ `echo $file| wc -c` -eq 1 ]
   then
     file="0"
   fi
   user=`rsh $1 " lsuser $v_user 2> .errouser"`
   if [ -z `echo $user` ]
    then
     errouser="Erro-User "`rsh $1 "cat .errouser"`
   fi
   userid=`echo $user | awk -F"," '{ print $1}'`
   filespace=`rsh $1 "df -k $v_tool_home 2>.errospace | grep -v Filesystem "`
   if [ `echo $filespace | wc -c` -eq 1 ]
   then
echo "entrei no file space"
     errofilespace="Erro-FileSpace "`rsh $1 "cat .errospace"`
     filespaces="0"
   else
     filespaces=`echo $filespace | awk ' OFS="-" { print $4, $6}'`
   fi
   if [ $filespaces != "0" ]
   then
     errofilespace=`echo $filespace | grep -v Filesystem | tr -d '%' | \
     awk '{ 
           if ( $4 > 90 ) { print "Erro-FileSpace FileSystem quase cheio ="$4"%" }
           if ( $6 > 90 ) { print "Erro-FileSpace Tabela de Inodes quase cheia ="$6"%" }
         }'`
    fi 
   log=$cabec$file"|"$errofile"|"$userid"|"$errouser"|"$filespaces"|"$errofilespace
   echo $log >> .log
}


for i in `cat .nodes`
do
v_node_name=`echo $i | awk -F"|" ' {print $1}'`
v_tipo_node=`echo $i | awk -F"|" ' {print $2}'`
   if [ $v_tipo_node = "computernode" ]
   then
    fn_CheckDS $v_node_name
   elif [ $v_tipo_node = "datanode" ] 
   then
    fn_CheckDB2 $v_node_name
   elif [ $v_tipo_node = "sas" ]
    then
    fn_CheckSAS $v_node_name
   fi
done
cat .log | grep Erro
