#!/bin/bash

##################################################################################
#                                                                                #
#                         IIS Status      					                     #
#                                                                                #
#               Este script verifica o status dos servicos da plataforma IS      #
#                                                                                #
##################################################################################
#	IBM
#---------------------------------------------------------------------------------
#  @(#)  Script: ISstatus.sh                                       	Vrs: 1.0
#---------------------------------------------------------------------------------
#  Autor       : 
#---------------------------------------------------------------------------------
#  Data        : 07/08/2012 - Versao 1.0
#---------------------------------------------------------------------------------
#  Descricao : Script para monitorar o servicos da plataforma Information Server
#              WAS/Agents/DataStage Engine
#---------------------------------------------------------------------------------


usage()
{
     echo "Usage:"
     echo "${ScriptName}( [ -statusWAS ] [ -statusNA ] [ -statusDSE ] ) "
     echo "    -statusWAS:  shows the status of WAS on the local machine "
     echo "    -statusNA:   shows the status of NodeAgent on the local machine "
     echo "    -statusDSE:  shows the status of DataStage Engine on the local machine "
}

CheckASBNode() 
{
if [ -e $ASBHOME/bin/Agent.pid ]; then
	PID=`cat $ASBHOME/bin/Agent.pid`
	if [ `ps -ef | grep -v grep | grep -iwc $PID` -eq 2 ]; then
		echo "Agent Services running"
		PID=`cat $ASBHOME/bin/LoggingAgent.pid`
		if 	[ `ps -ef | grep -v grep |grep -iwc $PID` -eq 1 ]; then
			echo "Logging Agent running"
			return $rc_running
		else
            echo "Logging Agent not running, this will not affect the operation of DataStage, but needs verification!!!"
			return $rc_running
        fi
	else
		echo "Agent Services not running"
		return $rc_stoped
	fi	
else
	echo "Agent Services not running"
	return $rc_stoped
fi
}

CheckDSRPC() 
{
if [ `netstat -a | grep -i dsrpc | grep -i listen | wc -l ` -eq 1 ] ; then
	if [ `$DSHOME/bin/uv -admin -info | grep -i "engine status" | grep -i run | wc -l` -eq 1 ] ; then
			echo "DataStage Engine running" 
			# retorno de erro 110
			return $rc_running
	fi
else
	echo "DataStage Engine not running" 
	return $rc_stoped
fi
}

CheckWASTier() 
{
 if [ -e $WASHOME/profiles/InfoSphere/logs/server1/server1.pid ] ; then
	PID=`cat $WASHOME/profiles/InfoSphere/logs/server1/server1.pid`
	if [ `ps -ef | grep -v grep |grep -iwc $PID` -gt 0 ] ; then
	    if [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -eq 1 ] ; then
			echo "WAS service running" 
			return $rc_running
		elif [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -gt 1 ] ; then
			echo "WAS service starting" 
			return $rc_running  
		else
			echo "WAS service stoped" 
			return $rc_stoped
		fi
     fi		
elif [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -eq 0 ] ; then
		echo "WAS service stoped" 
		return $rc_stoped  
elif [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -gt 0 ] ; then
	    if [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -eq 1 ] ; then
			echo "WAS service running" 
			return $rc_running
		elif [ `ps -ef | grep -i server1 | grep -v grep  | grep -vE "startServer|stopServer|MetadataServer" | wc -l` -gt 1 ] ; then
			echo "WAS service starting" 
			return $rc_running
		else
			echo "WAS service stoped" 
			return $rc_stoped			
		fi
else
			echo "WAS service stoped" 
			return $rc_stoped					
fi
}


###############################################
###############################################
###############################################
#        main script 					      #
###############################################
###############################################
###############################################


statusWAS() #Above STATUS function customized to monitor just the WAS component
{
CheckWASTier
exit $?
}

statusNA() #Above STATUS function customized to monitor just the NodeAgent component
{
CheckASBNode
exit $?
}

statusDSE() #Above STATUS function customized to monitor just the NodeAgent component
{
CheckDSRPC
exit $?
}

#-----------------------------
#----------Parametros---------
#--OBS : Alterar path DIRLOG

. `cat /.dshome`/dsenv

DIR_WAS_BIN=$ASBHOME/../ASBServer
DIR_AGENT_BIN=$ASBHOME/bin
export WASHOME=$ASBHOME/../../WebSphere/AppServer/
export HomeDirectory=`dirname $0`
export ScriptName=`basename $0`
export rc_running=110
export rc_stoped=100


if [ $# -eq 0 ];then
     usage
     exit 1
fi

while [ ${#} -ne 0 ]
do
     case `echo ${1}`
     in
          -statusWAS)
               statusWAS
               shift
               ;;
          -statusNA)
               statusNA
               shift
               ;;
          -statusDSE)
               statusDSE
               shift
               ;;
          *)
               usage
               shift
               ;;
     esac
done

