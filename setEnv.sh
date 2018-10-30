if [ -f .erro ]
then
   rm -f .erro
fi
   
function trataErro
{
	 erro=`cat .erro | grep Status | awk '{ print $4 }'| tr -d [:space:]`
	 if [ $erro -eq 0 ]
	 then
	    echo "Variavel "$1" foi alterada no projeto: "$2
	 else
        echo " Erro ao alterar variavel "$1" no projeto: "$2
        cat .erro
     fi		
}   
   
echo "Digite a variavel de ambiente que sera modificada" 
read var
echo "Entre com o valor da variavel de ambiente que sera modificada"
read valor
echo "Entre com o nome do projeto para adicao da variavel: ALL(para todos)"
read proj
if [ $proj = "ALL" ]
then
  for i in `dsjob -lprojects`
  do
     dsadmin -envset $var -value $valor $i 2> .erro
	 trataErro $var $i
  done
else
     dsadmin -envset $var -value $valor $proj 2> .erro
	 trataErro $var $proj
fi

