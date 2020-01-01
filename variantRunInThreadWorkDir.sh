#!/bin/bash

set -e -o pipefail
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
# The sub printRunStartArraysFastq is taken from plateScreen96.sh main script, and modified here.

function finish {

if [ $? != "0" ]; then

echo
date
echo
echo "RUN CRASHED ! oneThreadParallelFastqWorkDir.sh for ${capturesiteFolderRelativePath} - check qsub.err to see why !"
echo

echo "runOK 0" > ${SGE_O_WORKDIR}/${capturesiteFolderRelativePath}/capturesiteRoundSuccess.log

else
    
echo
date
printThis="oneThreadParallelFastqWorkDir.sh : Analysis complete for fastq_${capturesiteCounter} ! "
printToLogFile
    
fi
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

echo "oneThreadParallelCapturesiteWorkDir.sh - by Jelena Telenius, 26/05/2018"
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
echo "oneThreadParallelCapturesiteWorkDir.sh" $@
echo

parameterList=$@
#------------------------------------------


# The fastq number is the task number ..
capturesiteCounter=$SGE_TASK_ID

# Writing the queue environment variables to a log file :
# ./${capturesiteFolderRelativePath}/variantEchoer_for_SunGridEngine_environment.sh > listOfAllStuff_theQueueSystem_hasTurnedOn_forUs.log

printThis="capturesite_${capturesiteCounter} : Run VA analysis capturesite-wise .. "
printNewChapterToLogFile
  
    capturesiteFolderRelativePath=$(cat runlistings/region${capturesiteCounter}.txt | head -n 1 | cut -f 1)

    cd ${capturesiteFolderRelativePath}        
    pwd
    echo

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
    
    printThis="runOK ${runOK}"
    printToLogFile
    echo "runOK ${runOK}" > capturesiteRoundSuccess.log
    
# ----------------------------------------
# All done !

exit 0

