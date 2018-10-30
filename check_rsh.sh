for i in `cat default.apt | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
do
  for y in `cat default.apt | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
  do
    echo " Servidor Origem" $i 
    echo "Servidor Destino" $y
    data_d=`rsh $i "rsh "$y" date"`
    echo "Data Servidor de Origem : "`date`
    echo "Data Servidor de Destino: "$data_d 
    echo "Usuario servidor de Origem: "`id` 
    user_id=`rsh $i "rsh "$y" id"`
    echo "Usuario servidor de Destino: "$user_id 
   done
done

