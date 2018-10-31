#!/usr/bin/ksh
#----------------------------------------------------------------------------
#  SCRIPT SHELL PARA IMPORT DE OBJETOS - DATASTAGE
#  Sintax: ./script_Import_ISX.sh <Arquivo.isx> <Projeto>
#----------------------------------------------------------------------------

######################################################
# Variaveis Pre-definidas
######################################################

export PATH=$PATH:/software/IS/Clients/istools/cli
CAMINHO=/stage/tmp/isx
DIRLOG=/stage/tmp/log
FILEAUT=/home/dsadm/authfile.dll


######################################################
# Parametros passados
######################################################

ARQUIVO=$1
PROJETO=$2


######################################################
# Variaveis Geradas
######################################################

DATAINI=`date '+%d/%m/%Y-%H:%M'`
DATA=`date +%Y%m%d%H%M%S`
SERVER=`hostname`
LOG=${DIRLOG}/IMPORT_ISX_${PROJETO}_${DATA}.log


echo "INICIO DO DEPLOY ${DATAINI}" > ${LOG}
echo "Arquivo a ser feito o Deploy - ${ARQUIVO}" >> ${LOG}

######################################################
# Verifica Parametros
######################################################


if [ -f ${CAMINHO}/${ARQUIVO} ]; then
        echo "Arquivo ${ARQUIVO} encontrado com sucesso" >>${LOG}
else
        echo "Arquivo ${ARQUIVO} não encontrado" >>${LOG}
        exit 15
fi


if [ "${PROJETO}" != "" ]; then
        echo "Nome do Projeto ${PROJETO} " >>${LOG}
else
        echo "O Nome do Projeto não foi informado!" >>${LOG}
        exit 25
fi


######################################################
# Comando de Import
######################################################

istool import -dom ${SERVER}:9080 -af $FILEAUT -r -ar ${CAMINHO}/${ARQUIVO} -ds ${SERVER}/${PROJETO} >> ${LOG}
CDRET=$?


######################################################
# Verifica o Import
######################################################

if [ $CDRET -eq 0 ]; then
        CDRES="Success"
elif [ $CDRET -eq 1 ]; then
        CDRES="Warning"
elif [ $CDRET -eq 2 ]; then
        CDRES="Partial failure"
elif [ $CDRET -eq 3 ]; then
        CDRES="Error reading from console"
elif [ $CDRET -eq 4 ]; then
        CDRES="Invalid command history index"
elif [ $CDRET -eq 5 ]; then
        CDRES="Error reading from script file"
elif [ $CDRET -eq 11 ]; then
        CDRES="Invalid command syntax"
else
        CDRES="Erro desconhecido"
fi


echo "***********************************" >> ${LOG}
echo "RESULTADO DO DEPLOY = $CDRES" >> ${LOG}
echo "***********************************" >> ${LOG}
cat ${LOG}
echo "ARQUIVO DE LOG: ${LOG}"

exit $CDRET

