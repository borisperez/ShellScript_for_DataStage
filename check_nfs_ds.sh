  for y in `cat default.apt | grep fastname | awk '{ print $2}'| tr -d '\"' | sort | uniq`
  do
    echo " Servidor Origem" hostname 
    echo "Servidor Destino" $y
    rsh $y " ls /software/db2 | wc -l" 
   done

