execProject()
{
getProjects
if [ -s .projects ] ; then
        while read line
        do
                cd $line
                export project=`basename $line`
                for i in `find . -name OshScript.osh`
                do
                        ( cd `dirname $i` ; validaDb2EE ; validaDb2CC)
                done
        done < .projects
fi
}

getProjects()
{
dssh <<EOF > .proj
SELECT 'RESULT|'||PATH FMT '50T' FROM UV_SCHEMA WHERE SCHEMA_NAME <> 'CATALOG';
EOF
cat .proj | tail -n +7 | grep "RESULT" | awk -F"|" '{ print $2}' > .projects
rm -f .proj
}

validaDb2EE()
{
osh="OshScript.osh"
job=`head -1 $osh | awk '{print $8}'`
v=0
while read line
do
        if [ "$line" = "db2load" ] ; then
                v=1
                continue
        fi
        if [ $v = 1 ] ; then
                if [ "$line" = "-nonrecoverable" ] ; then
                        v=0
                        continue
                fi
                if [ "$line" = "#################################################################" ] || [ "$line" = "# End of OSH code" ] ; then
                        echo "Job "$project" -> "$job" fazendo load sem o parametro nonrecoverable (DB2EE)!!!"
                        exit
                fi
        fi
done < $osh
}

validaDb2CC()
{
osh="OshScript.osh"
job=`head -1 $osh | awk '{print $8}'`
v=0
while read line
do
        if [ "$line" = "pxbridge" ] ; then
                v=1
                continue
        fi
        if [ $v <> 0 ] ; then
                if [ `echo $line|grep -c "\-XMLProperties"` = 1 ]; then
                        if  [ `echo $line|grep -c "Bulkload"` != 0 ] && [ `echo $line|grep -c "NonRecoverableTX modified=\\\'1\\\'"` = 0 ]; then
                                v=2
                                continue
                        else
                                v=0
                                continue
                        fi
                fi
                if [ $v = 2 ] && [ `echo $line|grep -c "ccdb2"` = 1 ]; then
                        echo "Job "$project" -> "$job" fazendo load sem o parametro nonrecoverable (DB2Connector)!!!"
                        exit
                fi
                if [ "$line" = "#################################################################" ] || [ "$line" = "# End of OSH code" ] ; then
                        v=0
                        continue
                fi
        fi
done < $osh
}

#################### Main
execProject

