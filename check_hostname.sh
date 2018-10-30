for i in `cat default_edwp.apt | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
do
  for y in `cat default_edwp.apt | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
  do
    echo " Servidor Origem APT" $i >> teste.host.txt
    echo " Servidor Origem" `hostname` >> teste.host.txt 
    host_d=`rsh $i "rsh "$y" hostname"` 
    echo "Servidor de Destino: "$y  >> teste.host.txt
    echo "Servidor de Destino: "$host_d  >> teste.host.txt
   done
done

