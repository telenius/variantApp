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
echo "variantBigwigs.sh UCSCSIZES BIGWIGFOLDER"
echo ""
echo "Generates a bigwig 'file.bw' for all files 'file.bdg' in the run folder"
echo "the bdg files need to be sorted (a'la sort -k1,1 -k2,2n) "
echo "The generated bigwig files are put to BIGWIGFOLDER"
echo ""
echo "the UCSCSIZES file is the chrom.sizes file,"
echo "which can be fetched with ucsctools fetchChromSizes (downloadable from http://hgdownload.soe.ucsc.edu/admin/exe/ )"
echo ""

}

# ------------------------------------------
CCversion="0.0.1"
CCseqBasicVersion="variantBigwigs"
# -----------------------------------------
MainScriptPath="$( which $0 | sed 's/\/'${CCseqBasicVersion}'.sh$//' )"
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

ucscsizes=$1
bigwigfolder=$2

if [ ! -s "${ucscsizes}" ]; then
    
    echo "Cannot find UCSC chromosome sizes file '${ucscsizes}' - bigwig generation ABORTED ! " >> "/dev/stderr"
    usage
    exit 1 

fi

if [ "${bigwigfolder}" == "" ]; then

    bigwigfolder="BIGWIGS"    

fi

if [ ! -d "${bigwigfolder}" ]; then
    
    mkdir -p ${bigwigfolder}

fi

pwd
pwd >> "/dev/stderr"

for filename in ./*.bdg
do
  if [ -s "${filename}" ]
  then

    newname=$(echo ${filename} | sed 's/\.bdg$//')
    echo $filename

    echo \
    "${MainScriptPath}/bedGraphToBigWig ${filename} ${ucscsizes} ${bigwigfolder}/${newname}.bw"
    echo \
    "${MainScriptPath}/bedGraphToBigWig ${filename} ${ucscsizes} ${bigwigfolder}/${newname}.bw" >> "/dev/stderr"
     ${MainScriptPath}/bedGraphToBigWig ${filename} ${ucscsizes} ${bigwigfolder}/${newname}.bw

  fi

done;

# If some variants went empty - making fake bigwig here with one region zero depth, to make the graphs work later on

weHaveEmtpyOnes=0
set +o pipefail
weHaveEmtpyOnes=$(($( ls -1 ./*.bdg_EMPTY | wc -l )))
set -o pipefail

if [ "${weHaveEmtpyOnes}" -ne 0 ]; then

for filename in ./*.bdg_EMPTY
do
    
    newname=$(echo ${filename} | sed 's/\.bdg_EMPTY$//')
    echo "$filename as EMPTY variant file"
    
    col1=$( head -n 1 ${ucscsizes} | cut -f 1 )
    echo -e "${col1}\t1\t2\t0" > EMPTY.bdg
    ${MainScriptPath}/bedGraphToBigWig EMPTY.bdg ${ucscsizes} "${bigwigfolder}/${newname}".bw
    rm -f EMPTY.bdg
    
done;

fi

echo ""
date
echo "" 
echo "All done ! "
echo ""


