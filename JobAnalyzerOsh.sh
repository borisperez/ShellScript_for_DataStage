
main()
{
. `cat /.dshome`/dsenv
export TMP_DIR=/stage/tmp/qa_coleta
export REPORTS=/stage/tmp/qa_coleta/reports
export LOGDETAIL=/stage/tmp/qa_coleta/logdetail
export PATH=$DSHOME/bin:$PATH
set -x
getProjects
if [ -s .projects ] ; then
  while read line
  do
        cd $line 2>/dev/null
		pwd
            export project=`basename $line`
        for i in `find . -name OshScript.osh`
        do
           ( cd `dirname $i` ; getStOpFromOsh OshScript.osh )
        done
  done < .projects
fi
}

getProjects()
{
dssh <<EOF > .proj
SELECT 'RESULT|'||PATH FMT '50T' FROM UV_SCHEMA WHERE SCHEMA_NAME <> 'CATALOG';
EOF
cat .proj | tail -n +7 | grep "RESULT" | tr -d '\"' | sort | awk -F"|" '{ if ( length($2) > 1 ){ print $2}}'> .projects
rm -f .proj
}

getStOpFromOsh()
{
job=`head -1 $1 | awk '{print $8}'`
awk -v proj=$project -v job=$job '{
	 if ( $0 ~ "#### STAGE" || $0 ~ "#### CONTAINER" )
	 {
		row=FNR + 2
		if ( $0 ~ "#### STAGE" ) {
		FS=" "
		stagio = $3
		next
		} else {
		FS=":"
		split($2,v," ")
		stagio = "Container-"v[1]" :"$3
		}
	 } 
	 if ( row == FNR )
	 {
		print proj"|"job"|"stagio"|"$1
		next
	  }
	 	 
	 }' $1 >> $LOGDETAIL/StagioOperador.txt
}

#########################################################################################
main
