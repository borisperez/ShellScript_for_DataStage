##################################################################################
#                                                                                #
#                         Check Parametros Encrypted                             #
#                                                                                #
#               This script collects parameters of the type 'encrypted'          #
#               used in the projects/jobs and checks if there is any             #
#               security leak on the parameters utilization                      #
#               in the osh script from each parallel job.                        #
#                                                                                #
# Author: Boris Perez, IBM AVP Services                                          #
# Retorno    : list parametros tipo Encrypted ou list de osh                     # 
#             ou relatorio de jobs com desvio de seguranca                       #
# Historico  : Data       | Descricao                                            #
# Versao       -----------|------------------------------------------------------#
# 1.0.0        2011-19-07 | Codigo Original                                      #
#                                                                                #
##################################################################################

#
# Decide if they function will be executed against all projects or only one job
#
 whereCanI() 
 {
 set -x
 echo $projeto
 echo $job
 if [ `echo $projeto | tr '[:upper:]' '[:lower:]'` =  "all" ]
 then
 echo "Run All"
    runAll $FUNCTION
 elif [ -n $projeto -a -n $job ]
 then
  echo "Run no job"
     ehOshVisible $projeto 
     $FUNCTION
 elif [ `echo $projeto | tr '[:upper:]' '[:lower:]'` != "all" ]
 then
   echo "Run no projeto"
     runProject $FUNCTION 
 else
      # echo "Passagem de parametros errado !!!"
     usage
 fi
 } 2>/dev/null

#
# Execute the script against all jobs in all projects
#
 runAll()
 {
  set -x
   for projn in `dsjob -lprojects  2>/dev/null`
   do
   echo "Entrou runAll proj "$projn 
      export projeto=$projn
      runProject $1
   done

}

#
# Execute the script against all jobs in one project 
#
 runProject()
 {    
  set -x
  echo "Run projeto "$projeto
      ehOshVisible
	  clear  
      export proj=$projeto
	  echo "$(tput sgr0) $(tput cup 21 20)Analisando jobs do Projeto = $(tput bold)"$proj $(tput sgr0)
       for jobn in `dsjob -ljobs $proj  2>/dev/null`
       do
            for inv in `dsjob -linvocations $proj $jobn  2>/dev/null`
            do
				  printf "$(tput bold)*$(tput sgr0)"
				  echo "Job "$inv
                  export job=$inv
				  $1
            done
       done
}


#
# Verify if the option OSHVisible is active for the log capture
#
ehOshVisible()
{
ehvisible=`dsadmin -listproperties $1 | grep OSHVisible | awk -F"=" '{ print $2}' 2>/dev/null`
if [ $ehvisible -eq "0" ]
then
  dsadmin -oshvisible TRUE $1 2>/dev/null
   echo " OSH nao estava visivel para o projeto: "$1 
   continue
fi
}

#
# create a xml report from the job by "dsjob -report"
#
 getJobReport()
{
echo "Passo 1 dsjob report"
dsjob -report $projeto $job XML 2>/dev/null > .jobReport
}

#
# seek parameters past on job from the XML report created on getJobReport function
#
 getParamFromReport()
{
 if [ -s .jobReport ]
 then
    echo "Passo 2 get params"
    paramrows=`grep -n ParamSet .jobReport | tr -d ParamSet | tr -d '\<' | tr -d '\>' | tr -d '\/' | tr -d [:space:] `
    v_head=`echo $paramrows | awk -F":" '{ print $2}'`
    v_tail=`echo $paramrows | awk -F":" '{ print $2 - $1}'`
        if [ -n $v_head ]
        then
            head -n$v_head .jobReport | tail -n$v_tail | tr -d '\"' | grep -E "Param Name|Type=1" | tr -d '\<' | tr -d '\>' | tr -d '\/' > .params
        else
			continue
        fi
 else
    continue
 fi
} 2>/dev/null

#
# Get encrypted parameters from the result of getParamFromReport function 
#
 getEncryptedParams()
 {
 linhaAnt="0"
 if [ -s .params ]
 then
     echo "Passo 3 get params encrypted"
linhaAnt="0"
    while read linha
    do
        linha=`echo $linha | tr -d [:blank:]`
        tipo=`echo $linha | awk -F"=" '{print $1}'`
        if [ $tipo = "Type" ]
        then
           echo `echo $linhaAnt | awk -F"=" '{split($2,v, ".") ; if ( length(v[2]) > 1 ) {; print v[2] ; } else {; print $2} }'` > .used_params
		fi
         linhaAnt=$linha
    done < .params
         groupParams
 else
     continue
 fi
 } 2>/dev/null

#
# Get wave number from the result of getJobReport function
#
 getJobWave()
 {
 if [ -s .jobReport ] 
 then
     echo "Passo 4 get wave"
     wave=`grep -E "Status=|WaveNo=" .jobReport | grep -v "StageStatus=" | tr -d '\"' | \
     awk -F'=' 'BEGIN { ORS="|" } { print $2 }' | tr -d '\n' | awk -F'|' ' { print $2 }' `
 else
     wave=""
    continue
 fi
 } 2>/dev/null

#
# Create a log of latest job run  
#
 getJobLog()
{
 if [ -n $wave ]
 then
   echo "Passo 5 get log detail"
  dsjob -logdetail $projeto $job -wave $wave 2>/dev/null > .jobLog
 else
   rm -f .jobLog
   continue
 fi
} 2>/dev/null

#
# Colect osh script from result of getJobLog
#
 getOshFromLog()
 {
  if [ -s .jobLog ]
  then
     echo "Passo 6 get osh from log"
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

#
# Separates suspect jobs with evidence 
#
 checkValidate()
 {
  if [ -s .oshLog ]
  then
    echo "Passo 7 check"
    while read linha
    do
      evidencia=`grep $linha .oshLog | grep -iv password`
        if [ -n $evidencia ]
        then
		echo "Tem evidencia "$evidencia
		   echo "#-------------Security Password-----------------#" >> .job_evidencia
           echo " Projeto="$projeto" Job="$job" Com falha de seguranca!!!!!" >> .job_evidencia
           echo $evidencia	>> .job_evidencia
		   echo "#-------------Enviar para Analise---------------# \n" >> .job_evidencia
	    fi
    done < .used_param
   else
   		echo "Nao tem evidencia "$evidencia
	 continue
   fi
 } 2>/dev/null

#
# Create a groups from the result of  getEncryptedParams function
#
 groupParams()
 {
 if [ -s .used_params ]
 then
     cat .used_params | sort | uniq > .used_param
         cat .used_param >> .used_params_hist
         rm -f .used_params
 else
   continue
 fi
 } 2>/dev/null

 usage()
{
     echo "Used:"
     echo "Comamnd syntax:"
     echo " $(tput bold) `basename $0` $(tput sgr0)( [ $(tput bold) -params $(tput sgr0)] [ $(tput bold) -osh $(tput sgr0)] [ $(tput bold) -validate $(tput sgr0)] ) [ $(tput bold) argumentos $(tput sgr0)] \n"
     echo " $(tput bold)     -params   : $(tput sgr0)Colect parameters names encrypted type used in the Jobs "
     echo " $(tput bold)     -osh      : $(tput sgr0)Colect osh scripts from the jobs "
     echo " $(tput bold)     -validate : $(tput sgr0)Validate osh script if they have ecrypted parameters used in other field types \n"
     echo " $(tput bold)     argumentos: $(tput sgr0) (< $(tput bold)all $(tput sgr0)> ou < $(tput bold)Projeto $(tput sgr0)> < $(tput bold)Job $(tput sgr0)>) \n"
     echo "  Exemple 1 -> $(tput bold) `basename $0` -validate all $(tput sgr0)" 
     echo "          * Perform the validation in all the jobs of all projects "
     echo "  Exemple 2 -> $(tput bold) `basename $0` -validate DW CargaDW $(tput sgr0)"
     echo "          * Perform the validation in the job CargaDW of the DW project "

}

 getParams()
 {
 getJobReport
 getParamFromReport
 }

 getOsh()
 {
  getParams
  getEncryptedParams
  getJobWave
  getJobLog
  getOshFromLog
 }

 getValidate()
 {
 getOsh
 checkValidate
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
export DSHOME=/software/IS/Engine/Server/DSEngine
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
        ;;
       *)
        usage
        ;;
     esac


