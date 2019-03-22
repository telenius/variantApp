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
# Gnu Public License (GPL3) license.                                     #
#                                                                        #
# variantApp  is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GPL3 license for more details.                                         #
#                                                                        #
# You should have received a copy of the GPL3 license                    #
# along with variantApp .                                                #
##########################################################################

function finish {

if [ $? != "0" ]; then

echo
echo
date
echo "RUN CRASHED ! - check qsub.err to see why !"
echo
echo >> "/dev/stderr"          
echo "RUN CRASHED ! - check qsub.err to see why !" >> "/dev/stderr"          
echo >> "/dev/stderr"

exit 1

else

if [ "${parameterList}" != "-h" ] && [ "${parameterList}" != "--help" ]
then
echo >> "/dev/stderr"          
echo "Analysis complete !" >> "/dev/stderr"          
echo >> "/dev/stderr"          
fi

exit 0
    
fi
}
trap finish EXIT

# ------------------------------------------
CCversion="0.0.1"
CCseqBasicVersion="variantApp_serial"
# -----------------------------------------
MainScriptPath="$( which $0 | sed 's/\/'${CCseqBasicVersion}'.sh$//' )"
# -----------------------------------------
# No params given - help only, but exit code 1 run type ..
if [ $# -eq 0 ]
then  
  . ${MainScriptPath}/variantAppHelp.sh
  usage
  exit 1
fi
# -----------------------------------------
# Help-only run type ..
if [ $# -eq 1 ]
then
  parameterList=$@
  if [ ${parameterList} == "-h" ] || [ ${parameterList} == "--help" ]
  then
    . ${MainScriptPath}/variantAppHelp.sh
    usage
    exit 0
  fi
fi

#------------------------------------------
# Normal runs (not only help request) starts here ..
echo "${CCseqBasicVersion}.sh - by Jelena Telenius, 15/03/2019"
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
echo "${CCseqBasicVersion}.sh" $@
echo
#------------------------------------------
echo
echo "MainScriptPath ${MainScriptPath}"
echo
# -----------------------------------------

echo
echo "Loading subroutines .."

# To print help
. ${MainScriptPath}/variantAppHelp.sh
# To load sort command defaults
. ${MainScriptPath}/variantAppEnv.sh
# To combine counts after parallelisation
. ${MainScriptPath}/variantfileCombine.sh
# To merge combined counts after parallelisation
. ${MainScriptPath}/variantCountcombine.sh

# -----------------------------------------

echo "Setting default params .."

# Samtools version - defaulting to samtools 1
samtoolsVS=1
# samtoolsVS=0 (can be set via user flag in excecution stage)

# OBLIGATORY USER FLAGS
mpileBamfile='UNDEFINED'
mpileBedfile='UNDEFINED'
mpileFastafile='UNDEFINED'

# OPTIONAL USER FLAGS (overwriting defaults of samtools mpileup)

mpileOtherParams=""

# VISUALISATION params file ..

visualParamFile="UNDEFINED"

# Run modes
ONLYHUB=0
# only generate the visualisation
# the visualisation scripts are allowed to finish without crashing : so if they seem to have gone wrong,
# running with onlyhub should fix this.

# --------------------------------------

echo "Reading user-given params .."

# Catching this manually
set +e
OPTS=`getopt -o h,6,A,x,b:,l:,f:,v:,d: --long help,onlyhub,samtools0,samtools1,min-coverage:,min-base-qual: -- "$@"`
if [ $? != 0 ]
then
    usage
    exit 1
fi
set -e

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h) usage;exit 0 ; shift ;;
        -6) mpileOtherParams="${mpileOtherParams} -6" ; shift ;;
        -A) mpileOtherParams="${mpileOtherParams} -A" ; shift ;;
        -x) mpileOtherParams="${mpileOtherParams} -x" ; shift ;;
        -b) mpileBamfile=$2 ; shift 2;;
        -l) mpileBedfile=$2 ; shift 2;;
        -f) mpileFastafile=$2 ; shift 2;;
        -v) visualParamFile=$2 ; shift 2;;
        -d) mpileOtherParams="${mpileOtherParams} -d $2" ; shift 2;;
        --help) usage;exit 0 ; shift ;;
        --onlyhub) ONLYHUB=1 ; shift ;;
        --samtools0) samtoolsVS=0 ; shift ;;
        --samtools1) samtoolsVS=1 ; shift ;;
        --min-coverage) "${mpileOtherParams} --min-coverage $2" ; shift 2;;
        --min-base-qual) "${mpileOtherParams} --min-base-qual $2" ; shift 2;;
        --) shift; break;;
    esac
done

# -------------------------------------
# Dividing to "normal" and "only visualise" user cases ..

if [ "${ONLYHUB}" -ne 1 ]; then


# -------------------------------------

# Checking that samtools , and varscan are available ..

echo "This tool needs 'samtools'and 'varscan' toolkits :"

${MainScriptPath}/variantAppEnv.sh sam${samtoolsVS}
# the above will crash the whole script if they are not available
# user is responsible of loading the versions correctly via the variantPileEnv.sh script

echo
echo >> "/dev/stderr"

# -------------------------------------

# Checking that samtools is available for bamdividing as well ..

echo "This tool needs 'samtools' 1.* for bam dividing :"

${MainScriptPath}/variantAppEnv.sh bamdiv
# the above will crash the whole script if samtools not available
# user is responsible of loading the new enough version via the variantPileEnv.sh script

echo
echo >> "/dev/stderr"

# -------------------------------------

# Checking that bedtools is available ..

echo "and 'bedtools' 2.2* for combining files after parallel runs :"

# First - approximating bdg counts for the count merging ..

${MainScriptPath}/variantAppEnv.sh merge
# the above will crash the whole script if bedtools not available
# user is responsible of loading the new enough version via the variantPileEnv.sh script

echo
echo >> "/dev/stderr"

# -------------------------------------

echo "Checking that the input files exist .."
echo

inputFilesFine=1
if [ ! -s "${mpileBedfile}" ]; then
     echo "ERROR ! : Input BED file -l ${mpileBedfile} does not exist or is empty file !" >> "/dev/stderr"
     inputFilesFine=0
fi
if [ ! -s "${mpileFastafile}" ]; then
     echo "ERROR ! : Input FASTA file -f ${mpileFastafile} does not exist or is empty file !" >> "/dev/stderr"                                                                                      
     inputFilesFine=0
fi
if [ ! -s "${mpileBamfile}" ]; then
     echo "ERROR ! : Input BAM file -b ${mpileBamfile} does not exist or is empty file !" >> "/dev/stderr"                                                                                      
     inputFilesFine=0
fi

if [ "${inputFilesFine}" -eq 0 ]; then
     echo >> "/dev/stderr"
     echo "EXITING !" >> "/dev/stderr"
     echo  >> "/dev/stderr"
     exit 1
fi


# -------------------------------------

echo ""
echo '------------------------------'
echo "DIVIDING INPUT BAM"
echo ""

echo \
"${MainScriptPath}/variantBamdivide.sh -l ${mpileBedfile} -b ${mpileBamfile}"
echo \
"${MainScriptPath}/variantBamdivide.sh -l ${mpileBedfile} -b ${mpileBamfile}" >> "/dev/stderr"
 ${MainScriptPath}/variantBamdivide.sh -l ${mpileBedfile} -b ${mpileBamfile}

echo ""
echo "" >> "/dev/stderr"

echo '------------------------------'
echo "PILEUPS AND VARSCAN COUNTS"
echo ""

# If fasta path is relative path ..

if [ $(echo "${mpileFastafile}" | awk '{print substr(1,1)}') != "/" ]; then
    fullFastaPath=$(pwd)"/${mpileFastafile}"
else
    fullFastaPath="${mpileFastafile}"
fi

cd "DIVIDEDbams"

pwd
pwd >> "/dev/stderr"

# -------------------------------------

for folder in region*
do

if [ -d "${folder}" ]; then

cd "${folder}"

pwd
pwd >> "/dev/stderr"

echo \
"${MainScriptPath}/variantPile.sh -l ${folder}/region.bed -b ${folder}/region.bam -f ${mpileFastafile} --samtools${samtoolsVS} ${mpileOtherParams}"
echo \
"${MainScriptPath}/variantPile.sh -l ${folder}/region.bed -b ${folder}/region.bam -f ${mpileFastafile} --samtools${samtoolsVS} ${mpileOtherParams}" >> "/dev/stderr"
 ${MainScriptPath}/variantPile.sh -l region.bed -b region.bam -f ${fullFastaPath} --samtools${samtoolsVS} ${mpileOtherParams}

cd ..

fi

done

# -------------------------------------

cd ..

echo '------------------------------'
echo "COMBINING COUNTS"
echo ""

# Calling the subroutine to combine all counts to folder called COMBINEcounts.
# The structure of that folder is exactly the structure of any of the individual DIVIDEDbams/region* folder contents,
# to enable more flexible use of the visualisation script (used after the combining)

# Asking sort params (from the environment script)
memoryMegas="-1"
sortTempFolder="UNDEFINED"
setSortEnv

# Now, as sort params have been set, we can ask to combine counts (and sort them on the fly)

echo \
"combineCountfiles ${memoryMegas} ${sortTempFolder} "
echo \
"combineCountfiles ${memoryMegas} ${sortTempFolder}" >> "/dev/stderr"
 combineCountfiles ${memoryMegas} ${sortTempFolder}

echo ""
echo "" >> "/dev/stderr"

# -------------------------------------
# Dividing to "normal" and "only visualise" user cases ..

fi

# -------------------------------------

# Any case we visualise. 


echo '------------------------------'
echo "VISUALISING the counts"
echo ""

# Visualising is the last stage (and traditionally the most fragile)
# - so providing a rerun option --onlyhub to separately run this stage.

# This is also to support situations where the cluster disk area cannot see the public area (to make the data hub)
# If this is the case, potentially the bigwig generation (below) could be still done in cluster
# and after that restarting with --onlyHub to make the actual public hubs.

# This stage reads a PARAMETER FILE instead of command line flags,
# to make it clearer what needs to be set up and how

# This is essentially a serial run, and the most intensive part is the bigwig generation
# (it is not hugely heavy duty, but possibly a bit heavy for front ends - so if public area can only be seen in the front end,
# the above modification to the code would be needed

# ----------------------------
# second - making the bigwigs ..

if [ ! -s "${visualParamFile}" ]; then
    
    echo "Cannot find visualisation parameters file '${visualParamFile}' - visualisation ABORTED ! " >> "/dev/stderr"
    exit 1 

fi

# UCSCSIZES /here/is/my/UCSC.sizes.txt

cat "${visualParamFile}" | grep '^UCSCSIZES\s\s*'
cat "${visualParamFile}" | grep '^UCSCSIZES\s\s*' >> "/dev/stderr"

ucscSizes=$( cat "${visualParamFile}" | grep '^UCSCSIZES\s\s*' | sed 's/^UCSCSIZES\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )

# If ucscSizes path is relative path ..
if [ "$(echo "${ucscSizes}" | awk '{print substr($1,1,1)}')" != "/" ]; then
    fullUcscSizesPath=$(pwd)"/${ucscSizes}"
else
    fullUcscSizesPath="${ucscSizes}"
fi

# If parmeterfile path is relative path ..
if [ "$(echo "${visualParamFile}" | awk '{print substr($1,1,1)}')" != "/" ]; then
    fullParamFilePath=$(pwd)"/${visualParamFile}"
else
    fullParamFilePath="${visualParamFile}"
fi

cd "COMBINEDcounts"

pwd
pwd >> "/dev/stderr"

cd "BEDGRAPH"

loadNeededToolsMerge
mergewithinCountfiles

echo \
"${MainScriptPath}/variantBigwigs.sh ${fullUcscSizesPath} BIGWIGS"
echo \
"${MainScriptPath}/variantBigwigs.sh ${fullUcscSizesPath} BIGWIGS" >> "/dev/stderr"
 ${MainScriptPath}/variantBigwigs.sh ${fullUcscSizesPath} ../BIGWIGS

echo ""
echo "" >> "/dev/stderr"

cd ..

# ----------------------------
# Last - making the data hub ..

# SAMPLENAME testvariantsample
# GENOMENAME mm9
# UCSCSIZES /here/is/my/UCSC.sizes.txt
# SERVER http:/userweb.molbiol.ox.ac.uk
# SERVERPATH /public/telenius/DNase_PIPE/variants
# DISKPATH /t1-data/public/telenius/DNase_PIPE/variants

# Assumes subfolder BIGWIGS just under run folder - where the bigwigs to be visualised are.

echo \
"${MainScriptPath}/variantVisualise.sh ${visualParamFile}"
echo \
"${MainScriptPath}/variantVisualise.sh ${visualParamFile}" >> "/dev/stderr"
 ${MainScriptPath}/variantVisualise.sh ${fullParamFilePath}

echo ""
echo "" >> "/dev/stderr"


# The script visualises all the bigwig files in the folder it is started on (these bw's have hardcoded file names to enable the hub structure),
# and makes a data hub with the given name and location.

# ----------------------------------------------

cd ..

echo ""
date
echo "" 
echo "All done ! "
echo ""


