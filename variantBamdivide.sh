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

usage(){

echo "(C) Jelena Telenius 2019, GPL3"
echo ""
echo "variantBamdivide.sh -b BAM -l BED "
echo ""
echo "-b BAMFILE      file of mapped reads (BAM)"
echo "-l BEDFILE      list of positions (chr pos) or regions (BED)"
echo ""
echo "-h --help  print this help"
echo ""
echo "Divides the -b BAMFILE to smaller bam files, each of which overlapping one of the bed regions in the -l BEDFILE."
echo ""

}


# ------------------------------------------
CCversion="0.0.1"
CCseqBasicVersion="variantBamdivide"
# -----------------------------------------
MainScriptPath="$( which $0 | sed 's/\/'${CCseqBasicVersion}'.sh$//' )"
# -----------------------------------------
# No params given - help only, but exit code 1 run type ..
if [ $# -eq 0 ]
then  
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

. ${MainScriptPath}/variantAppEnv.sh

# -----------------------------------------

echo "Setting default params .."

# OBLIGATORY USER FLAGS

mpileBamfile='UNDEFINED'
mpileBedfile='UNDEFINED'

# --------------------------------------

echo "Reading user-given params .."

# Catching this manually
set +e
OPTS=`getopt -o h,b:,l: --long help -- "$@"`
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
        -b) mpileBamfile=$2 ; shift 2;;
        -l) mpileBedfile=$2 ; shift 2;;
        --help) usage;exit 0 ; shift ;;
        --) shift; break;;
    esac
done

# -------------------------------------

echo "Loading environment .."
echo

loadNeededToolsBamdivide

# Set the proper environment load commands to 
# variantBamdivideEnv.sh script, to be loaded here

# -------------------------------------

# Checking that samtools , and varscan are available ..

echo "This tool needs 'samtools' and toolkit :"

which samtools

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
echo "Samtools view (to divide bams) .. "
echo ""

cat ${mpileBedfile} | grep -v "^\s*$" | sort -k1,1 -k2,2n > curated.bed

totalRounds=$(($(cat curated.bed | grep -c "")))
# The above crahes if count is 0 - which is fine, as it shouldn't.

rm -f bamDivide.log
touch bamDivide.log

rm -rf DIVIDEDbams
mkdir DIVIDEDbams


# First round

    echo -n " 1 "
    echo " region 1 : " >> bamDivide.log
    rm -rf DIVIDEDbams/region1
    mkdir DIVIDEDbams/region1
    
    head -n 1 curated.bed > DIVIDEDbams/region1/region.bed
    cat DIVIDEDbams/region1/region.bed | sed 's/\s/:/' | sed 's/\s/-/' >> bamDivide.log

    echo "\
    samtools view -h -b -L DIVIDEDbams/region1/region.bed -o DIVIDEDbams/region1/region.bam ${mpileBamfile}" >> bamDivide.log
    samtools view -h -b -L DIVIDEDbams/region1/region.bed -o DIVIDEDbams/region1/region.bam ${mpileBamfile}


if [ "${totalRounds}" -gt 1 ]; then

    for i in $( seq 2 $((${totalRounds})) )
    do
    
    echo -n " ${i} "   
    echo -n " region ${i} : " >> bamDivide.log
    rm -rf DIVIDEDbams/region${i}
    mkdir DIVIDEDbams/region${i}
    
    head -n ${i} curated.bed | tail -n 1 > DIVIDEDbams/region${i}/region.bed
    cat DIVIDEDbams/region${i}/region.bed | sed 's/\s/:/' | sed 's/\s/-/' >> bamDivide.log
    
    echo "\
    samtools view -h -b -L DIVIDEDbams/region${i}/region.bed -o DIVIDEDbams/region${i}/region.bam ${mpileBamfile}" >> bamDivide.log     
    samtools view -h -b -L DIVIDEDbams/region${i}/region.bed -o DIVIDEDbams/region${i}/region.bam ${mpileBamfile}

    done

fi

echo ""
date
echo "" 
echo "All done ! "
echo ""


