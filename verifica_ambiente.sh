
echo "##################Testes RSH no Config File##############"
for i in `cat /software/IS/Engine/Server/Configurations/default_edwp.apt | grep fastname | tr -d '\"' | awk '{print $2}' | sort | uniq`
do
echo "#########################################################"
echo "Conectando no $i"
rsh $i "( cd /software/IS/Engine/Server/ | wc -l )"
echo "Conectado com sucesso!"
echo ""
echo "Numero de processos OSH executando no momento:"
rsh $i "ps -ef | grep osh | wc -l"
echo "Numero de filesystems com 100% de utilizacao:" 
rsh $i "df -k . | grep 100"
echo "#########################################################"
echo ""
echo ""
done


echo "###########Orchadmin Check####################"
export APT_CONFIG_FILE=/software/IS/Engine/Server/Configurations/default_edwp.apt
export APT_PM_CONDUCTOR_HOSTNAME="caudwdsp02-app"
orchadmin check
echo "##############################################"

echo  "#########Port Listening DataStage############"
netstat -a | grep dsrpc
echo "#############################################"

echo "###############Engine Status#################"
/software/IS/Engine/Server/DSEngine/bin/uv -admin -info
echo "#############################################"
