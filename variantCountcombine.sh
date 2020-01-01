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

mergeThisOne(){
 
nowtime=$(date +%T)
echo -n "  ${thisOne}  ${nowtime}  ..  "

if [ -s "varscanParsed_${thisOne}.pre_bdg" ];then

rm -f temp.bdg    
mv -f varscanParsed_${thisOne}.pre_bdg temp.bdg

echo \
"bedtools merge -d -1 -c 4 -o sum -i varscanParsed_${thisOne}.pre_bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}.bdg"
echo \
"bedtools merge -d -1 -c 4 -o sum -i varscanParsed_${thisOne}.pre_bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}.bdg" >> "/dev/stderr"
 bedtools merge -d -1 -c 4 -o sum -i temp.bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}.bdg

rm -f temp.bdg

else
  
echo "No file COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping editing .. "
echo "No file COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping editing .. " >> "/dev/stderr"
touch varscanParsed_${thisOne}.bdg_EMPTY
    
fi
 
}

mergeThisIndelOne(){
 
nowtime=$(date +%T)
echo -n "  ${thisOne}  ${nowtime}  ..  "

if [ -s "varscanParsed_${thisOne}.pre_bdg" ];then

rm -f temp.bdg    
mv -f varscanParsed_${thisOne}.pre_bdg temp.bdg

echo \
"bedtools merge -d -1 -c 4 -o sum -i varscanParsed_${thisOne}.pre_bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}_approximate.bdg"
echo \
"bedtools merge -d -1 -c 4 -o sum -i varscanParsed_${thisOne}.pre_bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}_approximate.bdg" >> "/dev/stderr"
 bedtools merge -d -1 -c 4 -o sum -i temp.bdg | sort -k1,1 -k2,2n > varscanParsed_${thisOne}_approximate.bdg

rm -f temp.bdg
 
 
else
  
echo "No file COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping editing .. "
echo "No file COMBINEDcounts/BEDGRAPH/varscanParsed_${thisOne}.pre_bdg found - skipping editing .. " >> "/dev/stderr"
touch varscanParsed_${thisOne}_approximate.bdg_EMPTY
    
fi
 
}


mergewithinCountfiles(){

echo "" 
echo "Merging regions within count files .. "
echo ""
date
echo ""

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


thisOne="A"
mergeThisOne

thisOne="T"
mergeThisOne

thisOne="C"
mergeThisOne

thisOne="G"
mergeThisOne

thisOne="allcounts"
mergeThisOne

thisOne="allcountsQfiltered"
mergeThisOne

thisOne="allcountsQfilteredConsensus"
mergeThisOne

thisOne="INS"
mergeThisIndelOne

thisOne="DEL"
mergeThisIndelOne

nowtime=$(date +%T) 
echo "  merging finished at ${nowtime} "


}

echo ""
date
echo "" 
echo "All done ! "
echo ""


