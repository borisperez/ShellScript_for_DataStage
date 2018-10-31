#!/bin/ksh
##############################################################################
#
# SCRIPT NAME: ExecJob.sh
#
# DESCRIPTION: Generic shell-script to execute the following steps:
#	        -Prepare environment variables;
#	        -Define logging structures;
#	        -Resets Datastage job or sequence;
#	        -Runs Datastage job or sequence;
#	        -Removes temporary files;
#.
# PARAMETERS : 	
#	        RESTART          -> Will force the start of the sequence from the beginning
#                                    If empty, will run normally or start the sequence from where it stopped (if restartable)
# 
#       
# SINTAX: ExecJob.sh PARAMETROS <JOB_NAME> [RESTART] 
# 
#
########################################################################################################

PATH=$PATH:$DSHOME/bin

###########################
# Check parameters
###########################

# Using getopts to see if file name is passed as parameter
DSPROJECT=BX7
DSJOB=$1

## LOG_PARAM=`echo $DSJOB | tr 'a-z' 'A-Z'`

if [[ $# -le 5 ]]
then
   echo "  CopyBook         -> CopyBook from mainframe "
   echo "  TypeVariable     -> ASCII or EBCDIC  "
   echo "  InputFile        -> Input Path of dat file"
   echo "  OutputFile       -> Output Path of dat file"
   echo "  Column_Delimiter -> None or comma or ....	"
   echo "  Table_Name       -> Table name "
   exit 1
fi

# Set parameter for dsjob command 

##PARAM="-param CopyBook="$CopyBook" -param ##TypeVariable="$TypeVariable" -param InputFile="$InputFile" -##param OutputFile="$OutputFile" -param ##Column_Delimiter="$Column_Delimiter" -param ##Table_Name="$Table_Name
###########################
# Other variables
###########################
DATE=`date +%Y%m%d`
TIME=`date +%H%M%S`
LOG_FILE=/PROD/LOGS/$PROC.$DSPROJECT.$DSJOB.$DATE.$TIME.log
LJOBS_FILE=/PROD/LOGS/$PROC.$DSPROJECT.$DSJOB.ljobs.$DATE.$TIME.tmp
JOBINFO_FILE=/PROD/LOGS/$PROC.$DSJOB.jobinfo.$DATE.$TIME.tmp


###########################
# Functions
###########################
Error()
{
   echo `date "+%Y-%m-%d %H:%M:%S"` "ERROR: $1" >> $LOG_FILE
   cat $LOG_FILE
   echo "Log: $LOG_FILE"
   rm -f $JOBINFO_FILE
   rm -f $LJOBS_FILE
   exit 99
}

echo "################################################" >> $LOG_FILE
echo "# Project: $DSPROJECT\n#     Job: $DSJOB" >> $LOG_FILE
echo "################################################" >> $LOG_FILE
echo `date "+%Y-%m-%d %H:%M:%S"` Start. >> $LOG_FILE

##########################################################################################
# Step 1: Reset Datastage job or sequence
##########################################################################################
echo `date "+%Y-%m-%d %H:%M:%S"` "Reset Datastage job or sequence." >> $LOG_FILE

#Get job information
dsjob -jobinfo $DSPROJECT $DSJOB 2>/dev/null >$JOBINFO_FILE
JobRestartable=`cat $JOBINFO_FILE | awk -F":" '$1 ~/Job Restartable/ {print $2}'`
JobStatus=`cat $JOBINFO_FILE | awk -F":" '$1 ~/Job Status/ {print $2}'`

if [[ "$JobRestartable" = "" || "$JobStatus" = "" ]]
then 
	Error "Getting job information (job name may be incorrect)."
fi

case $JobStatus in
       	" RUN OK (1)") 			RET=1 ;;
       	" RUN with WARNINGS (2)") 	RET=2 ;;
       	" RUN FAILED (3)") 		RET=3 ;;
       	" VALIDATION FAILED (13)")	RET=13 ;;
       	" STOPPED (97)") 		RET=97 ;;
       	*)       			RET=0 ;;
esac

if  [ $JobRestartable -eq 0 ] && [[ $RET -eq 3 || $RET -eq 13 || $RET -eq 97 ]]
then
	#If job is not restartable and needs Reset
	v_Reset=Y
elif  [[ $JobRestartable -eq 1 && "$LOG_PARAM" = "RESTART" ]]
then
	#If process is restartable but needs to be executed from the beginning
	v_Reset=Y
	#Verify if child-processes are sequences, if any they should be reset
	dssearch -ljobs -uses -oj -r $DSPROJECT $DSJOB 2>/dev/null > $LJOBS_FILE
	if [ `cat $LJOBS_FILE | grep -c "sequence job"` -ne 0 ]; then v_Child_Reset=Y; fi
else
	v_Reset=N
fi

# Reset Job or Sequence entered as parameter
if [ "$v_Reset" = "Y" ]
then
 	echo "----- Reset output for $DSJOB -----" >> $LOG_FILE
 	dsjob -run -mode RESET $DSPROJECT $DSJOB >> $LOG_FILE 2>> $LOG_FILE
 	rc=$?
 	echo "-----------------------------------" >> $LOG_FILE
 	if [ $rc -eq 0 ] 
 	then
 		echo "  $DSJOB reset finished." >> $LOG_FILE
 	else
		Error "$DSJOB reset ended with an error!"
  	fi
else
	echo "  $DSJOB does not need a RESET." >> $LOG_FILE
fi


# Reset child sequences if they exist 
# and if main process is restartable but needs to be executed from the beginning
if [ "$v_Child_Reset" = "Y" ]
then 
	for v_sequence_job in `cat $LJOBS_FILE | cut -d, -f1 | sort | uniq` 
	do
		SeqRestartable=`dsjob -jobinfo $DSPROJECT $v_sequence_job 2>/dev/null | awk -F":" '$1 ~/Job Restartable/ {print $2}'`
		if [ $SeqRestartable -eq 1 ]
		then
			echo "\n----- Reset output for $v_sequence_job -----" >> $LOG_FILE
        		dsjob -run -mode RESET $DSPROJECT $v_sequence_job >> $LOG_FILE 2>> $LOG_FILE
        		rc=$?
        		echo "--------------------------------------------" >> $LOG_FILE
        		if [ $rc -eq 0 ]
        		then
               		 	echo "  $v_sequence_job reset finished." >> $LOG_FILE
        		else
               		 	Error "$v_sequence_job reset ended with an error!"
        		fi
		fi
	done
fi

##########################################################################################
# Step 2: Runs Datastage job or sequence
##########################################################################################
echo `date "+%Y-%m-%d %H:%M:%S"` "Run job or sequence $DSJOB." >> $LOG_FILE

echo "----- Output -----" >> $LOG_FILE
dsjob -run -jobstatus $PARAM $DSPROJECT $DSJOB >> $LOG_FILE 2>> $LOG_FILE
rc=$?
echo "------------------" >> $LOG_FILE

if [ $rc -eq 1 ] 
then
   echo `date "+%Y-%m-%d %H:%M:%S"`" $DSJOB RUN OK!"`dsjob -report $DSPROJECT $DSJOB 2> /dev/null | awk -F"=" '$1 ~/elapsed/ {print $1"="$2}'` >> $LOG_FILE
else
   Error "$DSJOB finished with status `dsjob -report $DSPROJECT $DSJOB 2> /dev/null | awk -F"=" '$1 ~/Job status/ {print $2}'`"
fi


##########################################################################################
# Step 4: Remove temporary files
##########################################################################################
echo `date "+%Y-%m-%d %H:%M:%S"` "Clean work area." >> $LOG_FILE
rm -f $JOBINFO_FILE
rm -f $LJOBS_FILE

echo `date "+%Y-%m-%d %H:%M:%S"` End. >> $LOG_FILE
cat $LOG_FILE

exit 0
