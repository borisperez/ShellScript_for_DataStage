export OSH_INI="OSH script"
export OSH_FIM="End of OSH code"
export SCORE_INI="It has"
export SCORE_FIM="It runs"
export TMP_DIR=/stage/tmp/qa_coleta
export REPORTS=/stage/tmp/qa_coleta/reports
export LOGDETAIL=/stage/tmp/qa_coleta/logdetail

function main
{
while read line
do
	if [ ${#line} > 0 ] ; then
		export proj=`echo $line | awk -F"|" '{ print $1}'`
		export job=`echo $line | awk -F"|" '{ print $2}'`
		dsjob -logdetail $proj $job -wave 0 2> $LOGDETAIL/error/$job.error > $LOGDETAIL/$job.log
			if [ -s $LOGDETAIL/$job.log ] ; then
				getPart $SCORE_INI $SCORE_FIM $TMP_DIR/score/$job.log score
			else
				echo "Error get log job "$job" projeto ">> $TMP_DIR/job.log.erro
				continue
			fi
	else
		continue
	fi	
done < $TMP_DIR/novosjobs.txt2
}


function agregaApts {
rm -f $TMP_DIR/.todos.apt

grep -E 'node|fastname' $DSHOME/../Configurations/*.apt | grep -v pools | 
while read line
do
	if [ `echo $line | awk ' $2 == "node" {print "true"}'` ] ; then
		node=`echo $line | awk '{ print $3}' | tr -d '\"'`
		if [ `echo $node | awk ' $1 ~ /compute/ {print "true"}'` ] ; then
		tipo="computenode"
		elif [ `echo $node | awk ' $1 ~ /db2/ {print "true"}'` ] ; then
		tipo="datanode"
		elif [ `echo $node | awk ' $1 ~ /sas/ {print "true"}'` ] ; then
		tipo="sasnode"
		elif [ `echo $node | awk ' $1 ~ /headnode/ || $1 ~ /conductor/ {print "true"}'` ] ; then
		tipo="conductor"
		fi
		continue
	else
		fastname=`echo $line | awk '{ print $3}' | tr -d '\"'`
		echo $node"|"$fastname"|"$tipo >> $TMP_DIR/.todos.apt
	fi
done
cat $TMP_DIR/.todos.apt | sort | uniq > $TMP_DIR/configuracoes.apt
cat $TMP_DIR/configuracoes.apt | awk -F"|" 'OFS="|" { print $1, $3 } ' | sort | uniq > $TMP_DIR/nome_node.lkp
}


function getPart
{
set -x
# Parametros
# $1 -> Exemplos : OSH_INI="OSH script" ou SCORE_INI="It has"
# $2 -> Exemplos : OSH_FIM="End of OSH code" ou SCORE_FIM="It runs"
# $3 -> Caminho e nome do log
# $4 -> Extenção da parte gerada exemplo: tmp, score, osh...

echo `grep -n "$1" "$3" | cut -d ":" -f1` + 1 | bc | read ini
echo `grep -n "$2" "$3" | cut -d ":" -f1` - 1 | bc | read fim
echo $fim - $ini +1 | bc | read dif
head -$fim  "$3"  | tail -$dif |  awk -F"[" -v proj=$proj -v job=$job  ' $2 ~ /^op/ {print projt,job,$1}' | sort | uniq -c > $LOGDETAIL/$4/$proj_$job.$4
}


######################################################
main