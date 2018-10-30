if [ -f .erro ]
then
   rm -f .erro
fi
   
function trataErro
{
	 erro=`cat .erro | grep Status | awk '{ print $4 }'| tr -d [:space:]`
	 if [ $erro -eq 0 ]
	 then
	    echo " Adicionando variavel "$1" no projeto: "$2
	 else
        echo " Erro ao adicionar variavel "$1" no projeto: "$2
        cat .erro
     fi		
}   
   
echo "Digite a variavel de ambiente que sera adicionada"
read var
echo "Entre com o tipo da variavel de ambiente que sera adicionada [STRING | ENCRYPTED]"
read tipo
[[ $tipo == "STRING" || $tipo == "ENCRYPTED" ]] || exit
echo "Entre com o nome do projeto para adicao da variavel: ALL(para todos)"
read proj
if [ $proj = "ALL" ]
then
  for i in `dsjob -lprojects`
  do
     dsadmin -envadd $var -type $tipo -prompt $var $i 2> .erro
     trataErro $var $i $proj
  done
else
     dsadmin -envadd $var -type $tipo -prompt $var $proj 2> .erro
     trataErro $var $proj
fi
