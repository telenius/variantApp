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

loadNeededTools_samtools1(){

module purge
module load samtools/1.3
# Has to be 1.* (higher than 1.1 - as 1.1 is very confusing syntax, as it is the weird tide-over version between 0.* 1.*)
module load varscan/2.3.6
# tested in varscan 2.3.* (not known if works for other versions)
module list

}

loadNeededTools_samtools0(){

module purge
module load samtools/0.1.19
# Has to be 0.*
module load varscan/2.3.6
# tested in varscan 2.3.* (not known if works for other versions)

module list


}

loadNeededToolsBamdivide(){

module purge
module load samtools/1.3
# Has to be 1.* (higher than 1.1 - as 1.1 is very confusing syntax, as it is the weird tide-over version between 0.* 1.*)
module list

}

loadNeededToolsMerge(){

module purge
module load bedtools/2.25.0
# Has to be 2.2* (2.1* and older will not have the needed flags)
module list

}

checkEnv_samtools1(){

loadNeededTools_samtools1

which samtools
which varscan
# the above will crash the whole script if they are not available

module purge

}

checkEnv_samtools0(){

loadNeededTools_samtools0

which samtools
which varscan
# the above will crash the whole script if they are not available

module purge

}

checkEnv_Bamdivide(){

loadNeededToolsBamdivide

which samtools
# the above will crash the whole script if they are not available

module purge

}

checkEnv_Merge(){

loadNeededToolsMerge

which bedtools
# the above will crash the whole script if they are not available

module purge

}

setSortEnv(){

    # The whole sorting protocol is optimised for :
    # - big files
    # - small /tmp area (asking the temporary sort file location instead of assuming plenty of space in /tmp )
    # - big run dir disk space (or other big available disk space near-by the running folder)
    # - avoiding huge ram memory peaks (to avoid crashing and cluster instability due hitting memory limits)
    # This comes in the cost of more disk area usage and longer run time.
    # The sortTempFolder location should be selected so, that it is as close as possible to the actual run dir
    # to avoid unnecessary I/O during sorting.
    
memoryMegas=500
# How much the environment allows to take for sorting
sortTempFolder=$(pwd)/COMBINEDcounts
# Where the temporary files generated by 'sort' are stored when running
# Sort command defaults to /tmp
# but as this area is quite small in many cluster setups, setting it to 'rundir' or its ballpark is often better idea
# The above puts it to be the COMBINEDcounts folder where the sorting is done.



}

if [ "$1" == "sam1" ];then
   checkEnv_samtools1 
fi

if [ "$1" == "sam0" ];then
   checkEnv_samtools10
fi

if [ "$1" == "bamdiv" ];then
   checkEnv_Bamdivide 
fi

if [ "$1" == "merge" ];then
   checkEnv_Merge
fi

