#!/bin/ksh

##################################################################################
#                                                                                #
#                         IIS Startup/Shutdown                                   #
#                                                                                #
#               Este script tem a função de fazer start e shutdown               #
#               da plataforma Information Server nas versões 8.1 e 8.5           #
#                                                                                #
# Autor : Boris V. Perez(IBM PS), Marcos Viana(Itaú)                             #
# Versao :       Date          Name            Notes                             #
# 1.0.0         2011-06-01    ISStartStop.sh   Initial Version                   #
##################################################################################
################################  Parametros #####################################
DSHOME=/software/IS/Server/DSEngine

##################################################################################

dsstart()
{
echo "Starting Engine"
sudo su - dsadm -c "\$DSHOME/bin/uv -admin -start"
CheckEngine $1
}

dsstop()
{
echo "Stoping Engine"
ClearSessions
sudo su - dsadm -c "\$DSHOME/bin/uv -admin -stop"
CheckEngine $1
}

ClearOSHSession()
{
echo "Clear Client Sessions"
if [ `ps -ef | grep osh | grep -v grep | wc -l` -gt 0 ]
then
 ClearSession osh
fi
}

ClearDsapiSession()
{
if [ `ps -ef | grep dsapi| grep -v grep | wc -l` -gt 0 ]
then
ClearSession dsapi
fi
}

ClearDscsSession()
{
if [ `ps -ef | grep dscs | grep -v grep | wc -l` -gt 0 ]
then
ClearSession dscs
fi
}

ClearSession()
{
ps -ef | grep $1 | awk '{print $2}' | xargs kill -9 2>/dev/null
}

ClearSessions()
{
echo "Waiting Hold Sessions"
while [ `netstat -a | grep dsrpc | grep -v grep | grep -v LISTEN | grep -v FIN_WAIT | grep -v CLOSE_WAIT | wc -l` -gt 0 ]
do
contar=0
echo "Sessoes Abertas : '\n' "
ClearDsapiSession
ClearDscsSession
ClearOSHSession
if [ $contar -ne 5 ]
 then
 contar=`expr $contar + 1`
 echo "Tentativa de limpar sessoes : "$contar
 sleep 10
else
 echo "Tentativas de limpar sessoes sem sucesso!!!"
 exit 3
fi
done
}

CheckEngine()
{
if [ `netstat -a | grep dsrpc | grep -v grep | grep LISTEN | wc -l` -eq 1 ]
then
 echo "Servico do Engine iniciado."
 dsreturn $1 dsstart
else
  echo "Servico do Engine fora!!!"  
  dsreturn $1 dsstop
fi 
}

dsreturn()
{
if [ $1 =  $2 ]
then
echo " COM SUCESSO"
  exit 0
else
echo "SEM SUCESSO"
  exit 1
fi
}

###################################### Main ######################################

##################################################################################


#####################################  Agents  ###################################
################################  Parametros #####################################
ISHOME=/software/IS

##################################################################################

CheckRoot()
{
echo "Checking user Root"
  if [ `id|grep -c "uid=0(root)"` -ne 1 ]
  then
     echo "##########  Este start deve ser feito com o usuario root #############"
     exit 1
  fi
}


agstart()
{
 echo "Starting Agents"
 CheckRoot
 $ISHOME/Engine/ASBNode/bin/NodeAgents.sh start
 sleep 10
 CheckAgents $1
}

agstop()
{
 echo "Stoping NodeAgents"
 CheckRoot
 $ISHOME/Engine/ASBNode/bin/NodeAgents.sh stop
 CheckAgents $1
}




CheckAgents()
{
 echo "Checking Agents"
 if [ -f $ISHOME/Engine/ASBNode/bin/Agent.pid ]
 then
   AGENTE_PID=`cat $ISHOME/Engine/ASBNode/bin/Agent.pid `
      if [ `ps -ef| awk '{ print $2 }' | grep $AGENTE_PID |grep -v grep |wc -l 2>/dev/null` -eq 1 ]
      then
        echo "Servico dos Agentes iniciado no PID :"$AGENTE_PID
	
	agreturn $1 agstart
       fi
  else
    echo "Servico dos Agentes fora!!!"
	agreturn $1 agstop
  fi
}


agreturn()
{ 
if [ $1 =  $2 ]
then
echo " COM SUCESSO"
  exit 0
else
echo "SEM SUCESSO"
  exit 1
fi
}

#####################################  WAS  ######################################
################################  Parametros #####################################
ISHOME=/software/IS

##################################################################################

CheckRoot()
{
echo "Checking user Root"
  if [ `id|grep -c "uid=0(root)"` -ne 1 ]
  then
     echo "##################   Este start deve ser feito com o usuario root  #####################"
     exit 1
  fi
}

CheckWas()
{
echo "Checking Was"
if [ -e $ISHOME/Was.log ]
 then
   WAS_PID=`awk '/ADMU3000I/ {print $10}' $ISHOME/Was.log`
    if [ `ps -ef| awk '{ print $2 }' | grep $WAS_PID |grep -v grep |wc -l 2>/dev/null` -eq 1 ]
     then
         echo "Servico do WebSphere iniciado no PID :"$WAS_PID
		 wasreturn $1 wasstart
       fi
  else
    echo "Servico do WebSphere fora!!!"
	wasreturn $1 wasstop
  fi
}

wasstart()
{
wasstop1
echo "Starting Was"
CheckRoot
$ISHOME/ASBServer/bin/MetadataServer.sh run | tee > $ISHOME/Was.log
CheckWas $1
}


wasstop1()
{
CheckRoot
$ISHOME/ASBServer/bin/MetadataServer.sh stop
rm $ISHOME/Was.log
}


wasstop()
{
echo "Stoping Was"
CheckRoot
$ISHOME/ASBServer/bin/MetadataServer.sh stop
rm $ISHOME/Was.log
CheckWas $1
}

wasreturn()
{
if [ $1 = $2 ]
then
echo " COM SUCESSO"
  exit 0
else
echo " SEM SUCESSO"
  exit 1
fi
}


##################################################################################

CheckRoot()
{
echo "Checking user Root"
  if [ `id|grep -c "uid=0(root)"` -ne 1 ]
  then
     echo "Este start deve ser feito com o usuario root"
     exit 1
  fi
}




case $1 in
startds) dsstart dsstart  ;;
stopds)  dsstop dsstop ;;
startag) agstart agstart ;;
stopag)  agstop agstop ;;
startwas) wasstart wasstart ;;
stopwas)  wasstop wasstop ;;

esac

