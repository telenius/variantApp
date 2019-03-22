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

usage(){

echo "(C) Jelena Telenius 2019, GPL3"
echo ""
echo "variantPile.sh -b BAM -l BED -f FASTA [opts]"
echo ""
echo "-b BAMFILE      file of mapped reads (BAM)"
echo "-l BEDFILE      list of positions (chr pos) or regions (BED)"
echo "-f REFFILE      faidx indexed reference sequence file"
echo ""
echo "--samtools0  use samtools0.* series to pileups"
echo "--samtools1  use samtools1.* series to pileups"
echo "  VS 0.* and 1.* differ in their default behavior when it comes to R1 R2 reads overlapping each others"
echo "  (how are these counted - only once or twice for the overlapping part)"
echo ""
echo "-d 200000          Max per-BAM depth (set lower if want to avoid excessive memory usage)"
echo "--min-coverage  1  Minimum read depth at a position to make a call"
echo "--min-base-qual 30 Minimum base quality at a position to count a read"
echo ""
echo "-6   assume the quality is in the Illumina-1.3+ encoding"
echo "-A   count anomalous read pairs"
echo "-x    disable read-pair overlap detection (only available for samtools 1.*)"
echo ""
echo "More details of above parameters : see the help commands of the underlying tools 'samtools mpileup' and 'varscan readcounts'"
echo ""
echo "-h --help  print this help"
echo ""
echo "Runs samtools mpileup (to count pileups for each base) with a command like :"

mpileHardcodedParams='-B --ff 4 -I'
mpileBamfile='BAMFILE'
mpileBedfile='BEDFILE'
mpileFastafile='REFFILE'
mpileOtherParams='[opts]'
mpileBasedepth=200000

echo ""
echo "samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileOtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} > mpile.txt"
echo ""

echo "and varscan readcounts (to sum the counted bases up and filter for base quality) with a command like :"

varscanInputFile='mpile.txt'
varscanMinReadCoverage=1
varscanMinBaseQuality=30

echo ""
echo "varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out"
echo ""

}

# ------------------------------------------
CCversion="0.0.1"
CCseqBasicVersion="variantPile"
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
. ${MainScriptPath}/variantPileVisNorm.sh

# -----------------------------------------

echo "Setting default params .."

# Samtools version - defaulting to samtools 1
samtoolsVS=1
# samtoolsVS=0 (can be set via user flag in excecution stage)

# -----------------------------------------

# samtools mpileup 
# setting suitable default parameters, and flags.

# VS 0.* and 1.* differ in their default behavior when it comes to R1 R2 reads overlapping each others
# (how are these counted - only once or twice for the overlapping part)

# Here providing flags to run in either, depending what the user selected in run parameters.
# Also giving a couple of user flags - the same for VS 0 and VS 1 runs, and one extra for VS1 (which does not exist for VS0)

# HARDCODED PARAMETERS overwriting samtools mpileup default settings

#        -B           disable BAQ computation
#        --ff INT     filter flags: skip reads with mask bits set []
#        -I           do not perform indel calling

mpileHardcodedParams='-B --ff 4 -I'


# OBLIGATORY USER FLAGS

mpileBamfile='UNDEFINED'

#        -l FILE      list of positions (chr pos) or regions (BED) [null]
# this is one-liner for parallel runs (the regions of interest serve as parallelisation units)
# , and multiliner, if the script is used in serial fashion

mpileBedfile='UNDEFINED'

#        -f FILE      faidx indexed reference sequence file [null]
# this is the fasta reference genome

mpileFastafile='UNDEFINED'

# OPTIONAL USER FLAGS (overwriting defaults of samtools mpileup)

#        -6           assume the quality is in the Illumina-1.3+ encoding
#        -A           count anomalous read pairs
#        -x           disable read-pair overlap detection (only available for samtools 1.*)

mpileX=0
mpileOtherParams=""

# OPTIONAL USER FLAGS with pre-set default value (overwriting defaults of samtools mpileup)

#        -d INT       max per-BAM depth to avoid excessive memory usage [250]

mpileBasedepth=200000
# we want to go deep

# This results in run command format :
# samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileBtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} > mpile.txt

# --------------------------------------

# varscan readcounts
# setting suitable default parameters, and flags.

# HARFCODED COMMAND PARTS

varscanInputFile='mpile.txt'
# the samtools mpileup output file

# OPTIONAL USER FLAGS with pre-set default value (overwriting defaults of varscan readcounts)

#        --min-coverage  Minimum read depth at a position to make a call [1]
#        --min-base-qual Minimum base quality at a position to count a read [20]

varscanMinReadCoverage=1
# we want to report everything : for QC purposes
varscanMinBaseQuality=30
# varscan will count also the "all bases" count : so we get both counts to make the QC values (all bases VS bases with base score of 30 or higher)

# This results in run command format :
# varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out

# --------------------------------------

echo "Reading user-given params .."

# Catching this manually
set +e
OPTS=`getopt -o h,6,A,x,b:,l:,f:,d: --long help,samtools0,samtools1,min-coverage:,min-base-qual: -- "$@"`
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
        -x) mpileX=1 ; shift ;;
        -b) mpileBamfile=$2 ; shift 2;;
        -l) mpileBedfile=$2 ; shift 2;;
        -f) mpileFastafile=$2 ; shift 2;;
        -d) mpileBasedepth=$2 ; shift 2;;
        --help) usage;exit 0 ; shift ;;
        --samtools0) samtoolsVS=0 ; shift ;;
        --samtools1) samtoolsVS=1 ; shift ;;
        --min-coverage) varscanMinReadCoverage=$2 ; shift 2;;
        --min-base-qual) varscanMinBaseQuality=$2 ; shift 2;;
        --) shift; break;;
    esac
done

# -------------------------------------

echo "Loading environment .."
echo

if [ "${samtoolsVS}" -eq 1 ]; then
	loadNeededTools_samtools1
else
	loadNeededTools_samtools0
fi

# Set the proper environment load commands to 
# variantPileEnv.sh script, to be loaded here

# -------------------------------------

# Checking that samtools , and varscan are available ..

echo "This tool needs 'samtools' and 'varscan' toolkits :"

which samtools
which varscan
# the above will crash the whole script if they are not available

# Now (if requested) adding x to the parameters, if we have samtools1 ..
if [ "${mpileX}" -eq 1 ]; then
   if [ "${samtoolsVS}" -eq 1 ]; then
     mpileOtherParams="${mpileOtherParams} -x"
   else
     echo "WARNING ! : Samtools VS 0.* mpileup does not allow flag -x : removing flag '-x' from run command !"
     echo "WARNING ! : Samtools VS 0.* mpileup does not allow flag -x : removing flag '-x' from run command !" >> "/dev/stderr"
   fi
fi

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

echo "Starting run in :"
pwd
pwd >> "/dev/stderr"

echo -n "INFO ${mpileBedfile} "
cat ${mpileBedfile} | sed 's/\s/:/' | sed 's/\s/-/' 

echo ""
echo '------------------------------'
echo "Samtools pileup .. "
echo ""

echo \
"samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileBtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} > mpile.txt"
echo \
"samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileBtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} > mpile.txt" >> "/dev/stderr"
 samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileBtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} | awk '{if ($4 != 0) print $0}' > mpile.txt

# samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileBtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} | awk '{if ($4 != 0) print $0}' > mpile.txt
# above preventing reporting empty counts for bases, that would kill varscan

echo ""
echo "" >> "/dev/stderr"

echo '------------------------------'
echo "Varscan counts .."
echo ""

if [ -s mpile.txt ]; then

echo \
"varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out"
echo \
"varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out" >> "/dev/stderr"
 varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out

echo '------------------------------'
echo "Visualise and normalise the counts .."
echo ""

visNormVariantPile
# This calls subs in the variantPileVisNorm.sh file
# It doesn't need params from this file (only dependent on the varscan.out file)
# so could just as easily be called like
# ${MainScriptPath}/variantPileVisNorm.sh
# (but of course then the file above should have a 'main' rather than just the callable sub)

else
    
echo \
"mpile.txt is empty : no bam reads overlapping the region of interest (skipping counting)"
echo \
"mpile.txt is empty : no bam reads overlapping the region of interest (skipping counting)" >> "/dev/stderr"

fi

echo ""
date
echo "" 
echo "All done ! "
echo ""


