#!/bin/sh
# set -x

OUTDIR='/tmp'
DSHOMEDIR='/software/Engine/Server/DSEngine'
JOBPID=''


################################################################################
# Run truss on a given pid; get next 100 system calls or 5 seconds of output
################################################################################
runtruss()
{
    PIDACTIVE="$(ps -eo pid | grep $PID | awk '{print $1}')"
    if [ "$PID" = "$PIDACTIVE" ]
    then

        # run in background so truss can be stopped if not stuck in loop
        truss -afe -p $PID 2>&1 | head -100 >> $REPORTFILE 2>&1 &
        sleep 5

        trussPID="$(ps -eo pid,args | grep truss | grep $PID | awk '{print $1}')"
        if [ -n "$trussPID" ]
        then
            # truss command is still active; kill it
            kill "$trussPID"
        fi
    else
        echo >> $REPORTFILE
        echo "Cannot provide truss on pid $PID; must have terminated" >> $REPORTFILE
    fi
}

################################################################################
# Run or initiate calls to log ps, procstack and truss output on a given pid
################################################################################
examineproc()
{
        PIDACTIVE="$(ps -eo pid | grep $PID | awk '{print $1}')"
        if [ "$PID" = "$PIDACTIVE" ]
        then
            echo >> $REPORTFILE
            echo "***** procstack $PID *****" >> $REPORTFILE
            procstack $PID >> $REPORTFILE 2>&1
            echo >> $REPORTFILE
            echo "***** truss $PID *****" >> $REPORTFILE
            runtruss
        else
            echo >> $REPORTFILE
            echo "Cannot provide info on pid $PID; must have terminated" >> $REPORTFILE
        fi
}

################################################################################
# Log info about each osh section leader
################################################################################
examineprocs()
{
    OSHPIDLIST="$(ps -ef | grep osh | grep APT_PMsectionLeaderFlag | awk '{print $2}')"

    # Loop through osh pids
    for PID in $OSHPIDLIST
    do
        # Call function to do actual work on the current pid
        examineproc
    done
}

################################################################################
# main
################################################################################

    # process command line arguments
    while [ $# -gt 0 ]
    do
        case $1 in
            -jobpid)
                JOBPID="$2"
                shift
                ;;
            -outdir)
                OUTDIR="$2"
                shift
                ;;
            -dshomedir)
                DSHOMEDIR="$2"
                shift
                ;;
            *)
                echo
                echo "Syntax: data_collector [options]"
                echo
                echo "-jobpid <pid>   : pid of hung job's DSD.RUN"
                echo "-outdir <path>    : location for output file"
                echo "-dshomedir <path> : location for DSEngine home"
                echo
                exit 1
                ;;
        esac
        if [ $# -gt 0 ]
        then
            shift
        fi
    done

    # ensure an appropriate output file location has been set
    if [ ! -d "$OUTDIR" ]
    then
        echo "Exiting...  $OUTDIR does not exit."
        exit
    fi
    REPORTFILE="$OUTDIR/hungprocess.`date +%m%d%Y`.`date +%H%M%S`.report"

    UNIX95=1
    export UNIX95

    # Log generic information such as ps and ipcs
    DATESTR="$(date)"
    echo "Report for hung job process $JOBPID on $DATESTR" > $REPORTFILE
    echo >> $REPORTFILE
    echo "***** ps -ef *****" >> $REPORTFILE
    ps -ef >> $REPORTFILE
    echo >> $REPORTFILE
    echo "***** proctree *****" >> $REPORTFILE
    proctree >> $REPORTFILE
    echo >> $REPORTFILE

    # Capture smat output
    echo >> $REPORTFILE
    echo "***** smat -a *****" >> $REPORTFILE
    if [ -d "$DSHOMEDIR" -a -f "$DSHOMEDIR"/dsenv ]
    then
        DSHOME=$DSHOMEDIR
        export DSHOME
        . $DSHOME/dsenv
        $DSHOME/bin/smat -a >> $REPORTFILE 2>&1
    else
        echo "Cannot provide smat output; incorrect DSEngine home directory, $DSHOMEDIR" >> $REPORTFILE
    fi

    # Log output specific to given DSD.RUN job pid
    case $JOBPID in
        [0-9]* )
            PID="$(ps -eo pid,args | grep $JOBPID | grep phantom | awk '{print $1}')"
            if [ "$JOBPID" = "$PID" ]
            then

                examineproc

                # Look for DSD.OshMonitor process; grab corresponding osh pid
                PIDOSH="$(ps -ef | grep $PID | grep OshMonitor | awk '{print $11}')"
                if [ "$PIDOSH" != "" ]
                then
                    PID=$PIDOSH
                    examineproc
                    examineprocs
                fi

            else
                echo "Did not collect job info; invalid pid $JOBPID"
            fi
            ;;
        * )
            echo "Did not collect job info; no pid specified"
            ;;
    esac