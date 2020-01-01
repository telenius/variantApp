#!/bin/bash

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

echo "(C) Jelena Telenius 2019, MIT license"
echo ""
echo "variantApp.sh -b BAM -l BED -f FASTA [ -v visualisationParameters.txt ] [opts]"
echo ""
echo "-b BAMFILE      file of mapped reads, sorted by coordinate (BAM)"
echo "-l BEDFILE      list of regions [chr str stp], tab-separated (BED)"
echo "-f REFFILE      faidx indexed reference sequence file"
echo "-v params.txt   parameters dictating visualisation of the variants (optional)"
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

echo "Runs samtools mpileup (to count pileups for each base) with a command like :"

mpileHardcodedParams='-B --ff 4 -I'
mpileBamfile='BAMFILE'
mpileBedfile='BEDFILE'
mpileFastafile='REFFILE'
mpileOtherParams='[opts]'
mpileBasedepth=200000

echo "samtools mpileup ${mpileHardcodedParams} -d ${mpileBasedepth} ${mpileOtherParams} -l ${mpileBedfile} -f ${mpileFastafile} ${mpileBamfile} > mpile.txt"
echo ""

echo "and varscan readcounts (to sum the counted bases up and filter for base quality) with a command like :"

varscanInputFile='mpile.txt'
varscanMinReadCoverage=1
varscanMinBaseQuality=30

echo "varscan readcounts mpile.txt --min-base-qual ${varscanMinBaseQuality} --min-coverage ${varscanMinReadCoverage} --output-file varscan.out"
echo ""
echo "Variant visualisation relies on a parameter file given in "
echo ""
echo "-v visualisationParameters.txt"
echo ""
echo "The parameter file can (but doesn't have to) contain the following parameters :"
echo ""
echo "SAMPLENAME testvariantsample"
echo "GENOMENAME mm9"
echo "UCSCSIZES /here/is/my/UCSC.sizes.txt"
echo "SERVER http:/userweb.molbiol.ox.ac.uk"
echo "SERVERPATH /public/telenius/DNase_PIPE/variants"
echo "DISKPATH /t1-data/public/telenius/DNase_PIPE/variants"
echo "USESYMBOLICLINKS"
echo ""
echo "The SERVERPATH and DISKPATH point to the same disk area - DISKPATH is how the computing nodes see it, SERVERPATH is how the same folder displays to the world in the public address."
echo "The SERVER/SERVERPATH combination (f.ex. http:/userweb.molbiol.ox.ac.uk/public/telenius/DNase_PIPE/variants) thus becomes the main folder of the visualisation files, where UCSC web browser can find them"
echo ""
echo "USESYMBOLICLINKS will make soft links to the generated bigwig files (linking, not copying files). Running without it generates true copies of the bigwig files to the DISKPATH area."
echo ""
echo "To run visualisation only (assumes otherwise complete run in the running folder) :"
echo "--onlyhub"
echo "This may be helpful in setting up a working combination of DISKPATH SERVERPATH and SERVER parameters above."
echo ""
echo "-h --help  print this help"
echo ""

}
