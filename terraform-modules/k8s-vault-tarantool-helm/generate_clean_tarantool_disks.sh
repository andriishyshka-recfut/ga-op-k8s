#!/bin/bash

START=${1}
END=${2}

TEMPLATE="job-clean-tarantool-disks_template.yaml"
RESULTS_FILE="generated_job.yaml"

echo > ${RESULTS_FILE}

for (( i=START; i<=END; i++ ))
do
    for j in {0..1}
    do
        sed -e "s/\<INDX_1\>/$i/g" $TEMPLATE | sed -e "s/\<INDX_2\>/$j/g" >> ${RESULTS_FILE}
        echo >> ${RESULTS_FILE}
        echo "---" >>  ${RESULTS_FILE}
    done
done