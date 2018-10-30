 runProject()
 {  
echo "  "
  set -x
      proj=$projeto
       for jobn in `dsjob -ljobs $proj  2>/dev/null`
       do
            for inv in `dsjob -linvocations $proj $jobn  2>/dev/null`
            do
                  export job=$inv
				  $1
            done
       done
}


 getJobReport()
{
 set -x
 echo "passo 1 report xml"
dsjob -report $projeto $job XML 2>/dev/null > .jobReport
}

 getJobWave()
 {
  set -x
  
 if [ -s .jobReport ] 
 then
 echo "passo 2 busca wave"
     wave=`grep -E "Status=|WaveNo=" .jobReport | grep -v "StageStatus=" | tr -d '\"' | \
     awk -F'=' 'BEGIN { ORS="|" } { print $2 }' | tr -d '\n' | awk -F'|' ' { print $2 }' `
 else
     wave=""
    continue
 fi
 } 2>/dev/null

  getJobLog()
{
 set -x
 if [ -n $wave ]
 then
 echo "passo 3 gera logdetail"
  dsjob -logdetail $projeto $job -wave $wave 2>/dev/null > .jobLog
 else
   rm -f .jobLog
   continue
 fi
} 2>/dev/null

 getOshFromLog()
 {
  set -x
  if [ -s .jobLog ]
  then
   echo "passo 4 coleta osh do log"
     oshrows=`grep -En "OSH script|End of OSH" .jobLog | cut -d: -f1`
     v_head=`echo $oshrows | awk '{ print $2}'`
     v_tail=`echo $oshrows | awk '{ print $2 - $1}'`
        if [ -n $v_head ]
        then
            head -n$v_head .jobLog | tail -n$v_tail > .oshLog
        else
		  rm -f .oshLog
          continue
        fi
  else
    rm -f .oshLog
	continue
  fi
 } 2>/dev/null
 
  checkOsh()
 {
  set -x
  if [ -s .oshLog ]
  then
    echo "passo 5 busca db2load"
	echo "##########Job= "$job >> .checkOsh
    grep -nE "db2load|-nonrecoverable" .oshLog >> .checkOsh
	echo "####################################### \n" >> .checkOsh
   else
	 rm -f .oshLog
   fi
 } 2>/dev/null
 
 
 whereCanI() 
 {
  set -x
 echo $projeto
 echo $job
     runProject $FUNCTION 

 } 2>/dev/null
 
 
 getOsh()
 {
  getJobReport
  getJobWave
  getJobLog
  getOshFromLog
  checkOsh
 }

##### ---------Main----------------- ######################################################################################
rm -f .params 2>/dev/null
rm -f .used_params 2>/dev/null
rm -f .oshLog 2>/dev/null
rm -f .jobLog 2>/dev/null
rm -f .jobReport 2>/dev/null
rm -f .job_evidencia 2>/dev/null

trap "" 2

wave=""
FUNCTION=""
export OPTION=$1
export projeto=$2
export job=$3
export DSHOME=/software/IS/Engine/Server/DSEngine/
. $DSHOME/dsenv
export PATH=$PATH:$DSHOME/bin

    case `echo ${OPTION} | tr '[:upper:]' '[:lower:]'`
     in
       -params)
        export FUNCTION=getParams
        whereCanI
        getEncryptedParams
        shift
        shift
        ;;
      -osh)
        export FUNCTION=getOsh
        whereCanI
        shift
        shift
        ;;
      -validate)
        export FUNCTION=getValidate
        whereCanI
        shift
        shift
        ;;
      -help)
        usage
        shift
        shift
        ;;
       *)
        usage
        shift
        ;;
     esac

