#!/usr/bin/ksh
#------------------------------------------------------------------------------------------
#     SCRIPT SHELL PARA IMPORT DE APLICACOES DO ISD
#     Sintax: ./script_Import_ISD.sh -f <Arquivo.dat> -i <INSTANCIAS> -q <MAX_QUEUESIZE>
#------------------------------------------------------------------------------------------


######################################################
# Variaveis Pre-definidas
######################################################

export PATH=$PATH:/software/IS/ASBNode/bin
CAMINHO=/stage/tmp/isx
DIRLOG=/stage/tmp/log
FILEAUT=/home/dsadm/authfile.dll


######################################################
# Parametros passados
######################################################

fileflag=
instflag=
queueflag=


while getopts 'f:i:q:' OPTION
do
	case $OPTION in
	f) fileflag=1
		pfile="$OPTARG"
		;;
	i) instflag=1
		pInst="$OPTARG"
		;;
	q) queueflag=1
		pqueue="$OPTARG"
		;;
	?) errflag=99
		;;
	esac
done
shift $((OPTIND -1))

ARQUIVO=$pfile
INSTANCIAS=$pInst
MAX_QUEUESIZE=$pqueue

######################################################
# Variaveis Geradas
######################################################

DATAINI=`date '+%d/%m/%Y-%H:%M'`
DATA=`date +%Y%m%d%H%M%S`
SERVER=`hostname`
USER=`grep user ${FILEAUT} | awk -F"user=" '{print $2}'`
PASSWD=`grep password ${FILEAUT} | awk -F"password=" '{print $2}'`
DS_USERID=`grep DS_USERID ${CAMINHO}/${ARQUIVO} | uniq | awk -F"=" '{print $3}' | sed 's/"//g' |  sed 's/\///g' | sed 's/>//g'`
APLICACAO=`grep rtiApplication ${CAMINHO}/${ARQUIVO} | awk -F" name=" '{print $2}' | sed 's/"//g' | sed 's/>//g' | head -1`
SERVICO=`grep rtiService ${CAMINHO}/${ARQUIVO} | awk -F" name=" '{print $2}' | sed 's/"//g' | sed 's/>//g' | head -1`
OPERACAO=`grep rtiOperation ${CAMINHO}/${ARQUIVO} |  awk -F" name=" '{print $2}' | sed 's/"//g' | sed 's/>//g' | head -1`
LOG=${DIRLOG}/IMPORT_ISD_${OPERACAO}_${DATA}.log


if [[ "$fileflag" != "1" ]] || [[ "$instflag" != "1" ]] || [[ "$queueflag" != "1" ]]; then
	echo "Parametros invalidos!\n Sintax Correta: ./script_Import_ISD.sh -f <Arquivo.dat> -i <INSTANCIAS> -q <MAX_QUEUESIZE>" >>${LOG}
	exit 5
fi



if [ -f ${CAMINHO}/${ARQUIVO} ]; then
        echo "Arquivo ${ARQUIVO} encontrado com sucesso" >>${LOG}
else
        echo "ARQUIVO ${ARQUIVO} NAO ENCONTRADO" >>${LOG}
        exit 15
fi


echo "INICIO DO DEPLOY - ISD ${DATAINI}" > ${LOG}
echo "Arquivo a ser feito o Deploy - ${ARQUIVO}" >> ${LOG}


Erro()
{
echo "**************************************************" >> ${LOG}
echo "Erro: $1" >> ${LOG}
echo "**************************************************" >> ${LOG}
cat ${LOG}
exit 99
}


importDAT()
{
echo "ISDImportExport.sh -act rti -af $FILEAUT -rep -inp $1" >> $2
ISDImportExport.sh -act rti -af $FILEAUT -rep -inp $1 >> $2 2>> $2
CRETimportDAT=`tail -1 $2 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETimportDAT -ne 0 ]; then
        Erro "Falha ao importar o arquivo: $1!"
fi
}


updateAGENT()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -k AGENT_HOST -nv $2" >> $3
ISDAdmin.sh -act update -af $FILEAUT -a $1 -k AGENT_HOST -nv $2 >> $3 2>> $3
CRETupdateAGENT=`tail -1 $3 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateAGENT -ne 0 ]; then
        Erro "Falha ao atualizar o AGENT_HOST: $2!"
fi
}


updateDS()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -k DS_HOST -nv $2" >> $3
ISDAdmin.sh -act update -af $FILEAUT -a $1 -k DS_HOST -nv $2 >> $3 2>> $3
CRETupdateDS=`tail -1 $3 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateDS -ne 0 ]; then
        Erro "Falha ao atualizar o DS_HOST: $2!"
fi
}


updateUSERID()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -k DS_USERID -ov $2 -nv $3" >> $4
ISDAdmin.sh -act update -af $FILEAUT -a $1 -k DS_USERID -ov $2 -nv $3 >> $4 2>> $4
CRETupdateUSERID=`tail -1 $4 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateUSERID -ne 0 ]; then
        Erro "Falha ao atualizar o DS_USERID de $2 para $3!"
fi
}


updatePASSWORD()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -pUr $2 -k DS_PASSWORD -nv $3" >> $4
ISDAdmin.sh -act update -af $FILEAUT -a $1 -pUr $2 -k DS_PASSWORD -nv $3 >> $4 2>> $4
CRETupdatePASSWORD=`tail -1 $4 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdatePASSWORD -ne 0 ]; then
        Erro "Falha ao atualizar o #DS_PASSWORD#!"
fi
}


updateMAX_ACTIVE()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MAX_ACTIVE -nv $4" >> $5
ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MAX_ACTIVE -nv $4 >> $5 2>> $5
CRETupdateMAX_ACTIVE=`tail -1 $5 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateMAX_ACTIVE -ne 0 ]; then
        Erro "Falha ao atualizar o MAX_ACTIVE=$4!"
fi
}


updateMIN_ACTIVE()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MIN_ACTIVE -nv $4" >> $5
ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MIN_ACTIVE -nv $4 >> $5 2>> $5
CRETupdateMIN_ACTIVE=`tail -1 $5 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateMIN_ACTIVE -ne 0 ]; then
        Erro "Falha ao atualizar o MIN_ACTIVE=$4 !"
fi
}


updateQUEUESIZE()
{
echo "ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MAX_QUEUESIZE -nv $4" >> $5
ISDAdmin.sh -act update -af $FILEAUT -a $1 -s $2 -o $3 -k MAX_QUEUESIZE -nv $4 >> $5 2>> $5
CRETupdateQUEUESIZE=`tail -1 $5 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETupdateQUEUESIZE -ne 0 ]; then
        Erro "Falha ao atualizar o MAX_QUEUESIZE=$4!"
fi
}


enableAplicacao()
{
echo "ISDAdmin.sh -action enable -af $FILEAUT -application $1" >> $2
ISDAdmin.sh -action enable -af $FILEAUT -application $1 >> $2 2>> $2
CRETenableAplicacao=`tail -1 $2 | grep -vc "COMMAND SUCCESSFULLY COMPLETED"`
if [ $CRETenableAplicacao -ne 0 ]; then
        Erro "Falha ao atualizar ao habilitar a aplicacao: $1!"
fi
}

########################################## Execucao ##########################################
importDAT ${CAMINHO}/${ARQUIVO} ${LOG}
updateAGENT ${APLICACAO} ${SERVER} ${LOG}
updateDS ${APLICACAO} ${SERVER} ${LOG}
updateUSERID ${APLICACAO} ${DS_USERID} ${USER} ${LOG}
updatePASSWORD ${APLICACAO} ${USER} ${PASSWD} ${LOG}
updateMAX_ACTIVE ${APLICACAO} ${SERVICO} ${OPERACAO} ${INSTANCIAS} ${LOG}
updateMIN_ACTIVE ${APLICACAO} ${SERVICO} ${OPERACAO} ${INSTANCIAS} ${LOG}
updateQUEUESIZE ${APLICACAO} ${SERVICO} ${OPERACAO} ${MAX_QUEUESIZE} ${LOG}
enableAplicacao ${APLICACAO} ${LOG}
##############################################################################################


echo "*************************" >> ${LOG}
echo "FIM DO DEPLOY" >> ${LOG}
echo "*************************" >> ${LOG}
cat ${LOG}


exit 0

