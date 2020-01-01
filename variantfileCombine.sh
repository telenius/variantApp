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

sortThisOne(){
 
nowtime=$(date +%T)
echo -n "  ${thisOne}  ${nowtime}  ..  "

weHaveTheseOnes=0
set +o pipefail
weHaveTheseOnes=$(($( ls -1 DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg | wc -l )))
set -o pipefail

if [ "${weHaveTheseOnes}" -ne 0 ];then

echo \
"sort -m -S ${memoryMegas}M -k1,1 -k2,2n -T ${sortTempFolder} DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg > COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg"
echo \
"sort -m -S ${memoryMegas}M -k1,1 -k2,2n -T ${sortTempFolder} DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg > COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg" >> "/dev/stderr"
 sort -m -S ${memoryMegas}M -k1,1 -k2,2n -T ${sortTempFolder} DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg > COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg   

else
  
echo "No files DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping combining them .. "
echo "No files DIVIDEDbams/region*/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping combining them .. " >> "/dev/stderr"
touch COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg_EMPTY
    
fi
 
# This whole sorting protocol is optimised for :
# - big files
# - small /tmp area
# - big run dir disk space
# - avoiding huge ram memory peaks
# This comes in the cost of more disk area usage and longer run time.
# The sortTempFolder location should be selected so, that it is as close as possible to the actual run dir
# to avoid unnecessary I/O during sorting.
 
}


combineCountfiles(){

echo "" 
echo "Combining count files .. "
echo ""
date
echo ""

rm -rf COMBINEDcounts
mkdir COMBINEDcounts
mkdir COMBINEDcounts/BEDGRAPH

# VISUALISATION TRACKS

# |-- BEDGRAPH
# |   |-- varscanParsed_A.bdg
# |   |-- varscanParsed_allcounts.bdg
# |   |-- varscanParsed_allcountsQfiltered.bdg
# |   |-- varscanParsed_allcountsQfilteredConsensus.bdg
# |   |-- varscanParsed_C.bdg
# |   |-- varscanParsed_DEL.pre_bdg
# |   |-- varscanParsed_G.bdg
# |   |-- varscanParsed_INS.pre_bdg
# |   `-- varscanParsed_T.bdg
   
# All the bdgs to be combined are sorted -k1,1 -k2,2n : so can be added with the merge method ..

# memoryMegas=500
# sortTempFolder=$(pwd)/COMBINEDcounts
# hardcoded to whatever the system it is ran in, will cope with
# set these in variantAppEnv.sh

thisOne="A"
sortThisOne

thisOne="T"
sortThisOne

thisOne="C"
sortThisOne

thisOne="G"
sortThisOne

thisOne="allcounts"
sortThisOne

thisOne="allcountsQfiltered"
sortThisOne

thisOne="allcountsQfilteredConsensus"
sortThisOne

thisOne="INS"
sortThisOne

thisOne="DEL"
sortThisOne

nowtime=$(date +%T) 
echo "  combining finished at ${nowtime} "


}