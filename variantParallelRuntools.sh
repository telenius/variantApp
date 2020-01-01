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

# ------------------------------------------

checkRunCrashes(){
# ------------------------------------------

# If we crashed uncontrollably, we will have runJustNow_*.log file(s) for the crashed run(s) still present.

howManyCrashes=0
howManyCrashes=$(($( ls -1 runJustNow_*.log 2>/dev/null | grep -c "" )))
checkThis="${howManyCrashes}"
checkedName='${howManyCrashes}'
checkParse

if [ "${howManyCrashes}" -ne 0 ]; then
  
  printThis="Some runs crashed UNCONTROLLABLY during the analysis \n ( this is most probably a bug - save your crashed output files and report to Jelena )."
  printNewChapterToLogFile
  
  printThis="In total ${howManyCrashes} of your runs crashed."
  printToLogFile
  
  printThis="These runs crashed :"
  printToLogFile

  printThis=$( ls -1 runJustNow_*.log | sed 's/runJustNow_//' | sed 's/.log//' | tr '\n' ' ') 
  printToLogFile
  
  printThis="They crashed in these steps :"
  printToLogFile

  printThis=$( cat runJustNow_*.log | sort -T $(pwd) | uniq -c ) 
  printToLogFile  
  
  weWillExitAfterThis=1
    
else
  printThis="OK - Checked for run crashes (due to bugs in code) - found none. Continuing. "
  printToLogFile   
fi

# ------------------------------------------
}

# ------------------------------------------

checkParallelCCanalyserErrors(){
# ------------------------------------------

# Check that no run crashes.

weWillExitAfterThis=0;
checkRunCrashes


# Check that no errors.

rm -f capturesiteRoundSuccess.log
for file in */capturesiteRoundSuccess.log
do
    
    thisCapturesiteName=$( basename $( dirname ${file} ))
    checkThis="${thisCapturesiteName}"
    checkedName='${thisCapturesiteName}'
    checkParse
    echo -en "${thisCapturesiteName}\t" >> capturesiteRoundSuccess.log 
    cat $file >> capturesiteRoundSuccess.log

done

howManyErrors=$(($( cat capturesiteRoundSuccess.log | grep -v '^#' | grep -cv '\s1$' )))
checkThis="${howManyErrors}"
checkedName='${howManyErrors}'
checkParse

if [ "${howManyErrors}" -ne 0 ]; then
  
  printThis="Some VA runs crashed ."
  printNewChapterToLogFile
  
  echo "These runs had problems :"
  echo
  cat capturesiteRoundSuccess.log | grep -v '^#' | grep -v '\s1$'
  echo
  
  cat capturesiteRoundSuccess.log | grep -v '^#' | grep -v '\s1$' > failedCapturesiterunsList.log
  
  printThis="Check which capture-site (REfragment) bunches failed, and why : $(pwd)/failedCapturesiterunsList.log ! "
  printToLogFile

  
# The list being all the fastqs in the original PIPE_fastqPaths.txt ,
# or if repair broken fastqs run, all the fastqs in PIPE_fastqPaths.txt which have FAILED in the previous run
# This allows editing PIPE_fastqPaths.txt in-between runs, to remove corrupted fastqs from the analysis.
# In this case the folder is just deleted and skipped in further analysis stages (have to make sure the latter stages don't go in numerical order, but rather in 'for folder in *' )
  
  
  weWillExitAfterThis=1
    
else
  printThis="All capture-site runs finished - moving on .."
  printNewChapterToLogFile   
fi

if [ "${weWillExitAfterThis}" -eq 1  ]; then
  printThis="EXITING ! "
  printToLogFile  
  exit 1
fi


# ------------------------------------------
}

prepareParallelCCanalyserRun(){
# ------------------------------------------

rm -rf runlistings
mkdir runlistings

rm -f runlist.txt
touch runlist.txt

for folder in region*
do

if [ -d "${folder}" ]; then
  
    # lister ..
    cp ${MainScriptPath}/variantEchoer_for_SunGridEngine_environment.sh ${folder}/.
    chmod u+x ${folder}/variantEchoer_for_SunGridEngine_environment.sh
    
    # All runs get the same run.sh
    JustNowFile=$(pwd)/runJustNow
    
    echo "${MainScriptPath}/variantPile.sh -l region.bed -b region.bam -f ${fullFastaPath} --samtools${samtoolsVS} ${mpileOtherParams}" > "${folder}/run.sh"
    echo "" >> "${folder}/run.sh"
    chmod u+x "${folder}/run.sh"

    # Run list update
    echo "${folder}" >> runlistings/${folder}.txt
    echo "${folder}" >> runlist.txt
    capturesitefileCount=$((${capturesitefileCount}+1))
    
    # If we go thread-wise in TMPDIR, we need to monitor the memory inside there ..
    if [ "${useWholenodeQueue}" -eq 0 ] &&[ "${useTMPDIRforThis}" -eq 1 ];then
        # TMPDIR memory usage ETERNAL loop into here, as cannot be done outside the node ..
        echo 'while [ 1 == 1 ]; do' > tmpdirMemoryasker.sh
        echo 'du -sm ${2} | cut -f 1 2>> /dev/null > ${3}runJustNow_${1}.log.tmpdir' >> tmpdirMemoryasker.sh                
        echo 'sleep 60' >> tmpdirMemoryasker.sh
        echo 'done' >> tmpdirMemoryasker.sh
        echo  >> tmpdirMemoryasker.sh
        chmod u+x ./tmpdirMemoryasker.sh  
    fi

fi    
    
done

# ------------------------------------------    
}
