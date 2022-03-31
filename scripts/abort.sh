#!/bin/bash
PARPID=$(cat .parallel.pid)
SCRPID=$(cat .script.pid )
#echo $PARPID
#echo $SCRPID
( ps -fNC grep | grep -e $SCRPID'.*llcalcs.sh' -e $SCRPID'.*hlcalcs.sh' >/dev/null ) && (
kill -s TERM $SCRPID  2> /dev/null
)
( ps -fNC grep | grep -E $PARPID'.*perl.*bin/parallel' >/dev/null ) && (
kill -s TERM $PARPID  2> /dev/null
kill -s TERM $PARPID  2> /dev/null
)

