#!/bin/bash

set -e -o pipefail

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

firstStepParser(){

# Makes chr str ELEMENT count file

# and outputs it to this file :
# varscanParsed_resolvedFirstStage.txt

# head resolvedFirstStage.txt
# chr2    69752276        A       13
# chr2    69752277        C       3
# chr2    69752278        A       4
# chr2    69752279        DEL-1-G 2



# #############################

echo "Parse the first steps.."

echo > firstStepParser.log
echo "Parse the first steps.."  >> firstStepParser.log
echo >> firstStepParser.log

rm -f varscanParsed_resolvedFirstStage.txt

# Take out the q-filtered total count column
# for normalisation
tail -n +2 ${file} | cut -f 5  > normcolumn.txt

tail -n +2 ${file} | cut -f 3-6 --complement | paste normcolumn.txt - > restOfFile.txt
rm -f normcolumn.txt

goOneMoreRound=1

while [ "${goOneMoreRound}" -ne "0" ]
do

echo -n " .. " 

echo -n " 1 "

rm -f tempFile.txt

echo -n " 2 " 
cat restOfFile.txt | sed 's/:/\t/' | sed 's/:/\t/' | cut -f 6 --complement > tempFile.txt

echo -n " 3 " 
# This is how it was before normalisation was added :
# cut -f 2-5 tempFile.txt | awk '{if ($3!="") print $0}' >> varscanParsed_resolvedFirstStage.txt
# chr1    18294613        A       2
# chr1    18294614        C       2       T:3:1:39:1:3:0
# chr1    18294615        A       2       T:1:1:20:1:1:0

# Make normalisation 1 per 100 (to get percentages)
cut -f 1-5 tempFile.txt | awk '{if ($4!="") print $2"\t"$3"\t"$4"\t"($5/$1)*100}' >> varscanParsed_resolvedFirstStage.txt
# 7698    chr1    18294613        A       2
# 7745    chr1    18294614        C       2       T:3:1:39:1:3:0
# 7746    chr1    18294615        A       2       T:1:1:20:1:1:0


echo -n " 4 " 
cut -f 4-5 --complement  tempFile.txt > restOfFile.txt

echo -n " 5 "
set +e
goOneMoreRound=$(($( cut -f 5 tempFile.txt | grep -vc "^\s*$" )))
set -e
rm -f tempFile.txt

echo -n " 6 " 
echo "" >> firstStepParser.log
echo "Will still need to process ${goOneMoreRound} lines !"   >> firstStepParser.log
echo ""  >> firstStepParser.log
echo "First 3 lines of the file remaining : "  >> firstStepParser.log
set +o pipefail
cat restOfFile.txt | awk '{if ($4!="") print $0}' | head -n 3  >> firstStepParser.log
set -o pipefail
echo "" >> firstStepParser.log
echo "#################"  >> firstStepParser.log
echo -n " 7 "

done

rm -f restOfFile.txt tempFile.txt


}

visNormVariantPile(){

# This is the varscan.out file location
file="varscan.out"

# --------------------------------------------

# 5) 

echo -n " all a "
tail -n +2 ${file} | awk '{if (substr($6,0,1)!=$3) print $1"\t"$2"\t"$2+1"\t"substr($6,0,1) }' | sort -k1,1 -k2,2n > varscanParsed_consNotRef.bed

# 6) 

echo -n " b "
tail -n +2 ${file} | cut -f 1-6 | sed 's/:/\t/' | sed 's/:/\t/' | cut -f 1,2,4,5,7 > varscanParsed_forMainAllele.txt

echo -n " c "
cat varscanParsed_forMainAllele.txt | awk '{print $1"\t"$2-1"\t"$2"\t"$3 }' | sort -k1,1 -k2,2n > varscanParsed_allcounts.pre_bdg
echo -n " d "
cat varscanParsed_forMainAllele.txt | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' | sort -k1,1 -k2,2n > varscanParsed_allcountsQfiltered.pre_bdg
echo -n " e "
cat varscanParsed_forMainAllele.txt | awk '{print $1"\t"$2-1"\t"$2"\t"$5 }' | sort -k1,1 -k2,2n > varscanParsed_allcountsQfilteredConsensus.pre_bdg
echo 

# --------------------------------------------

# If we have only ref alleleles, we don't do the below.

cat ${file} | cut -f 1-6 --complement > IsEmpty
if [ "$(grep -Lv "^\s*$" IsEmpty)" == "IsEmpty" ];then
    echo "INFO All alleles reference alleles - no need listing variants here ! "
    # rm -f IsEmpty
else

# rm -f IsEmpty
# Makes chr str ELEMENT count file
firstStepParser

# and outputs it to this file :
# varscanParsed_resolvedFirstStage.txt

# [telenius@deva 1_scripts]$ head ../../7_inspectMismatchesTestLocusChr2/testing/varscan_parsetest/resolvedFirstStage.txt 
# chr2    69752276        A       13
# chr2    69752277        C       3
# chr2    69752278        A       4
# chr2    69752279        DEL-1-G 2

# #############################

# Now we can parse the stuff out
# varscanParsed_resolvedFirstStage.txt


# DONE 0) samtools mpileup command
# 	VARSCAN command

# DONE 1) make one-column file with awk - chr str NAME count

# The following will be now done :

#  2) take the mismatches out from the rest of the file
#  3) separate ins and del
#  4) make ins del tracks
#  5) take out different CONS base name and position (if disagrees with FASTA ref)
#  6) make CONS track

# --------------------------------------------

# 2)

# Check which ones we have ..

weHaveG=1
weHaveC=1
weHaveT=1
weHaveA=1
weHaveINS=1
weHaveDEL=1

if [ "$(grep -L "\sG\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveG=0;fi
if [ "$(grep -L "\sC\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveC=0;fi
if [ "$(grep -L "\sT\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveT=0;fi
if [ "$(grep -L "\sA\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveA=0;fi

if [ "$(grep -L "\sINS-[1234567890]*-[A-Za-z]*\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveINS=0;fi
if [ "$(grep -L "\sDEL-[1234567890]*-[A-Za-z]*\s" varscanParsed_resolvedFirstStage.txt)" == "varscanParsed_resolvedFirstStage.txt" ];then weHaveDEL=0;fi


echo ""
echo "INFO Make bedgraphs of VARIANTS ( 0=no variants 1=some of these variants found ) .."
echo -n "INFO  G:${weHaveG}  "
if [ "${weHaveG}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep "\sG\s" | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' | sort -k1,1 -k2,2n > varscanParsed_G.pre_bdg
fi
echo -n "  C:${weHaveC}  "
if [ "${weHaveC}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep "\sC\s" | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' | sort -k1,1 -k2,2n > varscanParsed_C.pre_bdg
fi
echo -n "  T:${weHaveT} "
if [ "${weHaveT}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep "\sT\s" | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' | sort -k1,1 -k2,2n > varscanParsed_T.pre_bdg
fi
echo -n "  A:${weHaveA} "
if [ "${weHaveA}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep "\sA\s" | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' | sort -k1,1 -k2,2n > varscanParsed_A.pre_bdg
fi

# -------------------------------------------------

# 3) 

echo -n "  INS:${weHaveINS} "
if [ "${weHaveINS}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep INS | sort -k1,1 -k2,2n > varscanParsed_ins.temp
fi
echo -n " DEL:${weHaveDEL} "
if [ "${weHaveDEL}" == 1 ]; then
cat varscanParsed_resolvedFirstStage.txt | grep DEL | sort -k1,1 -k2,2n > varscanParsed_del.temp
fi

# --------------------------------------------------

# 4) 

# Insertions

if [ "${weHaveINS}" == 1 ]; then
# PILEUP bedgraph
echo -n " .. "
cat varscanParsed_ins.temp | awk '{print $1"\t"$2-1"\t"$2"\t"$4 }' > varscanParsed_INS.pre_bdg
# INSERTION SEQUENCES bed
echo -n " .. "
cat varscanParsed_ins.temp | sed 's/INS.*-//' | awk '{print $1"\t"$2"\t"$2+1"\t"$3 }' > varscanParsed_INS.bed
rm -f varscanParsed_ins.temp
fi


# PILEUP bedgraph
if [ "${weHaveDEL}" == 1 ]; then
echo -n " .. "
cat varscanParsed_del.temp | sed 's/-/\t/g' | awk '{ print $1"\t"$2"\t"$2+$4"\t"$6 }' > varscanParsed_DEL.pre_bdg
# DELETION SEQUENCES bed
echo -n " .. "
cat varscanParsed_del.temp | sed 's/-/\t/g' | awk '{ print $1"\t"$2"\t"$2+$4"\t"$5 }' > varscanParsed_DEL.bed
rm -f varscanParsed_del.temp
fi

# ----------------------------------------------

fi


mkdir BEDGRAPH
mv *.pre_bdg BEDGRAPH/.    
mkdir BED
mv *.bed BED/.


echo ""
date
echo ""
echo "Visualisation and normalisation done ! "
echo ""


}