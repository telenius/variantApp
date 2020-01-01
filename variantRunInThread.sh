#!/bin/bash

# set -e -o pipefail
# To crash the excecution if any of the underlying commands fail

##########################################################################
# Copyright 2019, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of variantApp .                                      #
#                                                                        #
# variantApp is free software: you can redistribute it and/or modify     #
# it under the terms of the                                              #
#                                                                        #
# MIT license.                                                           #
#                                                                        #
# variantApp  is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# MIT license for more details.                                         #
#                                                                        #
# You should have received a copy of the MIT license                    #
# along with variantApp .                                                #
##########################################################################

# This file fetches the fastqs in plateScreen96.sh style, the way that code was 21Feb2018
# The sub printRunStartArraysCapturesite is taken from plateScreen96.sh main script, and modified here.

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneThreadParallelCapturesite.sh for capturesite_${capturesiteCounter} - check qsub.err to see why !"
echo "Dumped files in ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}_CRASHED"
echo

echo "$(pwd) before cleaning up : "
ls -lht

echo "TMPDIR before cleaning up : "
ls -lht

mkdir ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}_CRASHED
mv -f ${TMPDIR}/* ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}_CRASHED/*

rm -f ${TMPDIR}/*

echo "TMPDIR after cleaning up"
ls -lht ${TMPDIR}

if [ ! -d ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath} ];then
mkdir ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}
fi
echo "runOK 0" > ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log

else

echo
date
printThis="oneThreadParallelCapturesite.sh : Analysis complete for ${capturesiteFolderRelativePath} ! "
printToLogFile
    
fi

kill ${tmpdirMmemoryAskerProcessnumber}
}
trap finish EXIT

printToLogFile(){
   
# Needs this to be set :
# printThis="" 

echo ""
echo -e "${printThis}"
echo ""

echo "" >> "/dev/stderr"
echo -e "${printThis}" >> "/dev/stderr"
echo "" >> "/dev/stderr"
    
}


printNewChapterToLogFile(){

# Needs this to be set :
# printThis=""
    
echo ""
echo "---------------------------------------------------------------------"
echo -e "${printThis}"
echo "---------------------------------------------------------------------"
echo ""

echo "" >> "/dev/stderr"
echo "----------------------------------------------------------------------" >> "/dev/stderr"
echo -e "${printThis}" >> "/dev/stderr"
echo "----------------------------------------------------------------------" >> "/dev/stderr"
echo "" >> "/dev/stderr"
    
}

# -----------------------------------------

# Normal runs (not only help request) starts here ..

echo "oneThreadParallelCapturesite.sh - by Jelena Telenius, 26/05/2018"
echo
timepoint=$( date )
echo "run started : ${timepoint}"
echo
echo "Script located at"
echo "$0"
echo

echo "RUNNING IN MACHINE : "
hostname --long

echo "run called with parameters :"
echo "oneThreadParallelCapturesite.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
capturesiteCounter=$SGE_TASK_ID

# Starting the memory monitoring ..
echo './tmpdirMemoryasker.sh ${capturesiteCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & '
echo "i.e."
echo "./tmpdirMemoryasker.sh ${capturesiteCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ & "
./tmpdirMemoryasker.sh ${capturesiteCounter} ${TMPDIR} ${SGE_O_WORKDIR}/ &
tmpdirMmemoryAskerProcessnumber=$!

# Writing the queue environment variables to a log file :
# ${capturesiteFolderRelativePath}/variantEchoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="capturesite_${capturesiteCounter} : Run VA analysis capturesite-wise .. "
printNewChapterToLogFile

capturesiteFolderRelativePath=$(cat runlistings/region${capturesiteCounter}.txt | head -n 1 | cut -f 1)

    # ##########################################
    # HERE PARALLEL MOVE TO TEMPDIR !
    
    printThis="Moving to TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    cd ${TMPDIR}
    echo
    echo "Here we are :"
    echo
    pwd
    echo
    
    cp -r ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/* .
    mv ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath} ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}_beforeTMPDIR
    
    echo
    echo "Copied over the parameter files :"
    echo
    
    ls -lht
    
    # ##########################################  

    echo "capture analysis started : $(date)"
    
      printThis="$(cat run.sh)"
      printToLogFile
        
      runOK=1
      ./run.sh
      if [ $? != 0 ]; then
      {
        runOK=0    

        printThis="Capturesite-wise CC analysis failed on line ${capturesiteCounter} of C_analyseCapturesiteBunches/runlist.txt ! "
        printToLogFile
        
      }
      fi  
    
    doQuotaTesting
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > capturesiteRoundSuccess.log
    
  
    # ##########################################
    # HERE PARALLEL MOVE BACK TO REAL DIR !
    
    printThis="Moving back to real life - from TMPDIR ${TMPDIR}"
    printNewChapterToLogFile
    
    printThis="moving data from "${TMPDIR}" to "${SGE_O_WORKDIR}
    printToLogFile
    
    ls -lR $(pwd) > TMPareaBeforeMovingBack.log

    mkdir ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}
    mv -f * ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/.
    
    printThis="emptying temp area ${TMPDIR}"
    printToLogFile
    
    rm -rf *
    
    printThis="returning to "${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}
    printToLogFile
    
    cd ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}
    echo
    echo "Here we are :"
    echo
    pwd
    echo
    
    ls -lR $(pwd) > TMPareaAfterMovingBack.log
    
    cat TMPareaBeforeMovingBack.log  | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -T $(pwd) -k2,2 -k1,1 | grep -v MovingBack > forDiff1.txt
    cat TMPareaAfterMovingBack.log   | sed 's/\s\s*/\t/g' | grep '^-' | cut -f 5,9 | sort -T $(pwd) -k2,2 -k1,1 | grep -v MovingBack > forDiff2.txt
    
    printThis="checking that all got moved properly"
    printToLogFile
    
    if [ $(($(diff forDiff1.txt forDiff2.txt | grep -c ""))) -ne 0 ]; then
        printThis="MOVE FAILED - run not fine ! "
        printNewChapterToLogFile
        
        runOK=0
    fi
    
    # Removing temp if all went fine
    if [ "${runOK}" -eq 1 ];then
        echo "would delete beforeTMPDIR here - but commenterd out "
        # rm -rf ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}_beforeTMPDIR
    fi
    
    cd ${SGE_O_WORKDIR}
    
    echo
    echo "Now all is clear - we can continue like we never went to TMPDIR ! "
    echo

    # ##########################################
    
    # Non-functinal symlink looks kinda bad, so getting rid of it now ..
    rm -f echoer_for_SunGridEngine_environment.sh
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > ${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

