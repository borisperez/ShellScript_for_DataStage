echo "Entre com o arquivo de configuração."
read apt_config

for i in `cat $apt_config | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
do
  for y in `cat apt_config | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
  do
    echo " De " $i "Para "$y
    rsh $i "rsh "$y" echo Foi | hostname"
    done
done

