set -x
v_data=`date +"%d%m%Y_%H%M"`
v_user=`whoami`

function fn_Clear
{
set -x
rm -f .log
}

### function fn_MontaLog
### {
#### }

function fn_CheckDS
{  
set -x
  for i in `cat .nodes | grep computernode`
  do
     v_node_name=`echo $i | awk -F"|" ' {print $1}'`
     for y in `cat .tools; cat .aptfile | grep $v_node_name`
     do
        v_tipo_tool=`echo $y | awk -F"|" ' {print $1}'`
        v_dir=`echo $y | awk -F"|" ' {print $2}'`
        fn_RshGet $v_node_name $v_tipo_tool $v_dir
     done
  done
}

function fn_CheckDB2
{
set -x
  for i in `cat .nodes | grep datanode`
  do
     v_node_name=`echo $i | awk -F"|" ' {print $1}'`
     for y in `cat .tools | grep DB2; cat .aptfile | grep $v_node_name`
     do
        v_tipo_tool=`echo $y | awk -F"|" ' {print $1}'`
        v_dir=`echo $y | awk -F"|" ' {print $2}'`
        fn_RshGet $v_node_name $v_tipo_tool $v_dir
     done
  done
}

function fn_CheckSAS
{ 
  for i in `cat .nodes | grep sas`
  do
     v_node_name=`echo $i | awk -F"|" ' {print $1}'`
     for y in `cat .tools | grep SAS ; cat .tools | grep Geral`
     do
        v_tipo_tool=`echo $y | awk -F"|" ' {print $1}'`
        v_dir=`echo $y | awk -F"|" ' {print $2}'`
        fn_RshGet $v_node_name $v_tipo_tool $v_dir
     done
  done
}

function fn_CheckAPTConfig
{
  v_node=`echo $1 | awk -F"|" '{ print $1 }'`
  v_dir=`echo $1  | awk -F"|" '{ print $2 }'`
  fn_RshGet $v_node "CheckAPT" $v_dir
}

function fn_TrataAPTConfig
{
set -x
cat $1 | egrep "fastname|resource" | tr -d '\"' | awk ' { print $1,$2,$3}' | \
  awk ' OFS="|" {
   if ( NF == 2 ) { 
     cpnode=$2
     next
    } else {
     resource=$3
   }
   print "aptfile", cpnode, resource
  }' | cut -d"/" -f1-4| awk -F"|" 'OFS="|" {print $1,$3,$2}' | sort | uniq > .aptfile
}

function fn_ALL
{
fn_CheckDS
fn_CheckDB2
fn_CheckSAS
}


function fn_RshGet
{
errofile=""
errouser=""
errofilespace=""
   cabec=`echo " $1| Check $2 | dir $3 | QtdFiles="`
   file=`rsh $1 " ls $3 2>.errofile | wc -l | tr -d [:space:]"`
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
   filespace=`rsh $1 "df -k $3 2>.errospace | grep -v Filesystem "`
   if [ -z "$filespace" ]
   then
     errofilespace="Erro-FileSpace "`rsh $1 "cat .errospace"`
     filespaces="0"
   else
     filespaces=`echo $filespace | awk ' OFS="-" { print $4, $6}'`
   fi
   if [ $filespaces != "0" ]
   then
     errofilespace=`echo $filespace | grep -v Filesystem | tr -d '%' | \
     awk '{
           if ( $4 > 50 ) { print "Erro-FileSpace FileSystem quase cheio ="$4"%" }
           if ( $6 > 90 ) { print "Erro-FileSpace Tabela de Inodes quase cheia ="$6"%" }
         }'`
    fi
   log=$cabec$file"|"$errofile"|"$userid"|"$errouser"|"$filespaces"|"$errofilespace
   echo $log >> .log
}

function fn_Execute
{
set -x
   if [ $1 = "fn_CheckDS" ]
   then
      fn_CheckDS
   elif [ $1 = "fn_CheckDB2" ]
   then
    fn_CheckDB2
   elif [ $1 = "fn_CheckSAS" ]
    then
    fn_CheckSAS
   elif [ $1 = "fn_ALL" ]
    then
    fn_ALL
   fi
}


fn_Clear
fn_TrataAPTConfig /software/IS/Engine/Server/Configurations/default_edwp.apt
fn_Execute "fn_CheckDB2"

