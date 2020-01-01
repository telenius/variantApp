#!/bin/bash

# not setting pipefail in here - this is just the visualisation part,
# and failing in here doesn't really mean anything.
# There is a flag to run just this part again in variantApp.sh ( --onlyHub )

##########################################################################
# Copyright 2019, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of variantApp .                                      #
#                                                                        #
# variantApp is free software: you can redistribute it and/or modify     #
# it under the terms of the                                              #
#                                                                        #
# MIT license.                                     #
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
echo "variantVisualise.sh PARAMETERFILE"
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
    
}

writeBeginOfHtml(){
    
    echo "<!DOCTYPE HTML PUBLIC -//W3C//DTD HTML 4.01//EN" > begin.html
    echo "http://www.w3.org/TR/html4/strict.dtd" >> begin.html
    echo ">" >> begin.html
    echo " <html lang=en>" >> begin.html
    echo " <head>" >> begin.html
    echo " <title> ${hubName} data hub in ${genomeName} </title>" >> begin.html
    echo " </head>" >> begin.html
    echo " <body>" >> begin.html
    
}

doMultiWigParent(){
    
    # NEEDS THESE TO BE SET BEFORE CALL :
    #longLabel=""
    #trackName=""
    #overlayType=""
    #windowingFunction=""
    #visibility=""
    
    echo ""                                        >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "#--------------------------------------" >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo ""                                        >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    
    echo "track ${trackName}"                      >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "container multiWig"                      >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "shortLabel ${trackName}"                 >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "longLabel ${longLabel}"                  >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "type bigWig"                             >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "visibility ${visibility}"                >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    #echo "aggregate transparentOverlay"           >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    #echo "aggregate solidOverlay"                 >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "aggregate ${overlayType}"                >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "showSubtrackColorOnUi on"                >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    #echo "windowingFunction maximum"              >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    #echo "windowingFunction mean"                 >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "windowingFunction ${windowingFunction}"  >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "configurable on"                         >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "autoScale on"                            >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "alwaysZero on"                           >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "dragAndDrop subtracks"                   >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "html description"                        >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo ""                                        >> ${diskpath}/${hubName}/${genomeName}/tracks.txt

}

doMultiWigChild(){
    
    # NEEDS THESE TO BE SET BEFORE CALL
    # parentTrack=""
    # trackName=""
    # fileName=".bw"
    # trackColor=""
    # trackPriority=""
    
    echo "track ${trackName}"                       >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "parent ${parentTrack}"                    >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "bigDataUrl ${fileName}"                   >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "shortLabel ${trackName}"                  >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "longLabel ${trackName}"                   >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "type bigWig"                              >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "color ${trackColor}"                      >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "html description"                         >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo "priority ${trackPriority}"                >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    echo ""                                         >> ${diskpath}/${hubName}/${genomeName}/tracks.txt
    
}



# --------------------------

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

# --------------------------

visualParamFile=$1

if [ ! -s "${visualParamFile}" ]; then
    
    echo "Cannot find visualisation parameters file ${visualParamFile} - visualisation ABORTED ! " >> "/dev/stderr"
    exit 1 

fi

# SAMPLENAME testvariantsample
# GENOMENAME mm9
# UCSCSIZES /here/is/my/UCSC.sizes.txt
# SERVER http:/userweb.molbiol.ox.ac.uk
# SERVERPATH /public/telenius/DNase_PIPE/variants
# DISKPATH /t1-data/public/telenius/DNase_PIPE/variants
# USESYMBOLICLINKS

cat "${visualParamFile}" | grep '^SAMPLENAME\s\s*'
cat "${visualParamFile}" | grep '^SAMPLENAME\s\s*' >> "/dev/stderr"

# ----------------------------

# Allowing super weird or missing parameters - sometimes people want to hack these
# without a properly working public area environment ..

hubName=""
set +e
hubName=$( cat "${visualParamFile}" | grep '^\s*SAMPLENAME\s\s*' | sed 's/^\s*SAMPLENAME\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )
set -e

if [ "${hubName}" == "" ]; then
    hubName="SAMPLE"
fi

genomeName=""
set +e
genomeName=$( cat "${visualParamFile}" | grep '^\s*GENOMENAME\s\s*' | sed 's/^\s*GENOMENAME\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )
set -e

if [ "${genomeName}" == "" ]; then
    genomeName="undefinedGenome_giveHereSomethingLike_mm9"
fi

server=""
serverpath=""
diskpath=""

set +e
server=$( cat "${visualParamFile}" | grep '^\s*SERVER\s\s*' | sed 's/^\s*SERVER\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )
set -e

if [ "${server}" == "" ]; then
    server="UNDEFINED_SERVER"
fi

set +e
serverpath=$( cat "${visualParamFile}" | grep '^\s*SERVERPATH\s\s*' | sed 's/^\s*SERVERPATH\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )
set -e

if [ "${serverpath}" == "" ]; then
    serverpath="UNDEFINED_SERVER_FOLDER"
fi

set +e
diskpath=$( cat "${visualParamFile}" | grep '^\s*DISKPATH\s\s*' | sed 's/^\s*DISKPATH\s\s*//' | sed 's/\s\s.*//' | tail -n 1 )
set -e

if [ "${diskpath}" == "" ]; then
    diskpath="UNDEFINED_PUBLICLY_VISIBLE_DISK_AREA"
fi

set +e
symlinks=$( cat "${visualParamFile}" | grep -c '^\s*USESYMBOLICLINKS\s*' )
set -e

# ----------------------------

echo ""
echo "Starting visualisation data hub generation with parameters : "
echo ""
echo "hubName ${hubName}"
echo "genomeName ${genomeName}"
echo "server ${server}"
echo "serverPath ${serverPath}"
echo "diskPath ${diskPath}"
echo "symlinks ${symlinks}"
echo ""

# ----------------------------

echo ""
echo "Checking bigwig file existence .."
echo ""

# |-- BIGWIG
# |   |-- varscanParsed_A.bw
# |   |-- varscanParsed_allcounts.bw
# |   |-- varscanParsed_allcountsQfiltered.bw
# |   |-- varscanParsed_allcountsQfilteredConsensus.bw
# |   |-- varscanParsed_C.bw
# |   |-- varscanParsed_DEL_approximate.bw
# |   |-- varscanParsed_G.bw
# |   |-- varscanParsed_INS_approximate.bw
# |   `-- varscanParsed_T.bw

inputBigwigsFine=1

if [ ! -s BIGWIGS/varscanParsed_A.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_T.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_C.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_G.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_allcounts.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_allcountsQfiltered.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_allcountsQfilteredConsensus.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_DEL_approximate.bw ]; then inputBigwigsFine=0; fi
if [ ! -s BIGWIGS/varscanParsed_INS_approximate.bw ]; then inputBigwigsFine=0; fi

if [ "${inputBigwigsFine}" -eq 0 ]; then

echo "Cannot find the all the needed input files, need to have these in the BIGWIG folder : " >> "/dev/stderr"
echo '' >> "/dev/stderr"
echo ' BIGWIGS' >> "/dev/stderr"
echo ' |-- varscanParsed_A.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_allcounts.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_allcountsQfiltered.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_allcountsQfilteredConsensus.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_C.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_DEL_approximate.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_G.bw' >> "/dev/stderr"
echo ' |-- varscanParsed_INS_approximate.bw' >> "/dev/stderr"
echo ' `-- varscanParsed_T.bw' >> "/dev/stderr"
echo '' >> "/dev/stderr"
echo 'EXITING !' >> "/dev/stderr"
echo '' >> "/dev/stderr"

exit 1
  
fi

# ----------------------------------

# Now starting to make hub .
# Not removing existing - so crashing if cannot create ..
# (safest way to provide clean restarts - users tend to make custom edits to their public visualisations
# and deserve a chance to save these mods, before they are brutally wiped out with whole folder delete or tracks.txt overwrite ..)

if [ -d "${diskpath}/${hubName}" ]; then
    echo "Cannot create directory '${diskpath}/${hubName}' as it is already there !" >> "/dev/stderr"
    echo "Rename / remove this existing data hub - and restart the visualisation generation." >> "/dev/stderr"
    echo "" >> "/dev/stderr"
    echo "EXITING !" >> "/dev/stderr"
    
    exit 1
fi

if [ ! -d "${diskpath}" ]; then
    mkdir -p ${diskpath}
fi

mkdir ${diskpath}/${hubName}
    
echo "hub ${hubName}" > ${diskpath}/${hubName}/hub.txt
echo "shortLabel ${hubName}" >> ${diskpath}/${hubName}/hub.txt
echo "longLabel ${hubName}" >> ${diskpath}/${hubName}/hub.txt
echo "genomesFile genomes.txt" >> ${diskpath}/${hubName}/hub.txt
echo "email jelena.telenius@gmail.com" >> ${diskpath}/${hubName}/hub.txt

mkdir ${diskpath}/${hubName}/${genomeName}

echo "genome ${genomeName}" > ${diskpath}/${hubName}/genomes.txt
echo "trackDb ${genomeName}/tracks.txt" >> ${diskpath}/${hubName}/genomes.txt
echo "" >> ${diskpath}/${hubName}/genomes.txt

mkdir ${diskpath}/${hubName}/logfiles

# -----------------------------------

# Symlinks, or data copy ..

if [ "${symlinks}" -eq 1 ]; then
echo ""
echo "Linking bigwig files to the public folder "
echo ""
    weAreHere=$(pwd)
    cd ${diskpath}/${hubName}/${genomeName}
    ln -s ${weAreHere}/BIGWIGS/*.bw .
    cd ${weAreHere}
else
echo ""
echo "COPYING bigwig files to the public folder (symlinks are not in use) .."
echo ""
    cp BIGWIGS/*.bw ${diskpath}/${hubName}/${genomeName}/.
fi

# Copying the normal files (assuming these are all log files) ..

rm -f logfilelist.txt
touch logfilelist.txt
for file in ../*
do
    if [ -f "${file}" ];then
        basename ${file} >> logfilelist.txt
        cp ${file} ${diskpath}/${hubName}/logfiles/.
    fi
done

# Parse the bed and sh files - to get them to SHOW in html (not to load as attachment)
cat logfilelist.txt | grep -v '.sh$' | grep -v '.bed$' > temp.txt
rm -f logfilelist.txt
mv temp.txt logfilelist.txt

for file in ../*.sh
do
    if [ -f "${file}" ];then
        echo $(basename ${file}).txt >> logfilelist.txt
        cp ${file} ${diskpath}/${hubName}/logfiles/$(basename ${file}).txt
    fi
done

for file in ../*.bed
do
    if [ -f "${file}" ];then
        echo $(basename ${file}).txt>> logfilelist.txt
        cp ${file} ${diskpath}/${hubName}/logfiles/$(basename ${file}).txt
    fi
done


# Making description page ..

    description="${diskpath}/${hubName}/${genomeName}/description.html"

    echo "<!DOCTYPE HTML PUBLIC -//W3C//DTD HTML 4.01//EN" > ${description}
    echo "http://www.w3.org/TR/html4/strict.dtd" >> ${description}
    echo ">" >> ${description}
    echo " <html lang=en>" >> ${description}
    echo " <head>" >> ${description}
    echo " <title> ${hubName} data hub in ${genomeName} </title>" >> ${description}
    echo " </head>" >> ${description}
    echo " <body>" >> ${description}
    echo "<h3>Sample : ${hubName}</h3>" >> ${description}
    
    echo "<p>Data produced "$(date)" </p>" >> temp_description.html
    
    echo "<p>" >> ${description}
    echo "Run located in : $(pwd)" >> ${description}
    echo "</p>" >> ${description}

    echo "<hr />" >> ${description}
    
    echo "<p>" >> ${description}
    echo "Log files constructed during the run :" >> ${description}
    echo "</p>" >> ${description}
    
    echo ""
    echo "cat logfilelist.txt"
    echo ""
    cat logfilelist.txt
    echo ""
    echo "cat logfilelist.txt | awk (etc..)"
    echo ""
    cat logfilelist.txt | awk '{print "<li><a target=\"_blank\" href=\"'${server}'/'${serverpath}'/'${hubName}'/logfiles/"$1"\" >"$1"</a> </li>"}'
    echo ""
    
    cat logfilelist.txt | awk '{print "<li><a target=\"_blank\" href=\"'${server}'/'${serverpath}'/'${hubName}'/logfiles/"$1"\" >"$1"</a> </li>"}'  >> ${description}
    
    echo "<hr />" >> ${description}
 
    # The end of  HTML file 
    echo "</body>" >> ${description}
    echo "</html>" >> ${description}

# -----------------------------------

# Now making the tracks ..


echo 'Making overlay track for :'
echo ' |-- varscanParsed_A.bw'
echo ' |-- varscanParsed_C.bw'
echo ' |-- varscanParsed_G.bw'
echo ' `-- varscanParsed_T.bw'
echo ''

    longLabel="${hubName} non-ref base % : A blue , T yellow , C red , G green"
    trackName="${hubName}_ATCG"
    overlayType="transparentOverlay"
    windowingFunction="maximum"
    visibility="full"
    doMultiWigParent
    
    # blue
    Acolor='0,0,200'
    # yellow
    Tcolor='255,211,0'
    # red
    Ccolor='255,74,179'
    # green
    Gcolor='62,176,145'
    
    parentTrack="${hubName}_ATCG"
    trackName="A"
    fileName="varscanParsed_A.bw"
    trackColor=${Acolor}
    trackPriority="20"
    doMultiWigChild
    
    parentTrack="${hubName}_ATCG"
    trackName="T"
    fileName="varscanParsed_T.bw"
    trackColor=${Tcolor}
    trackPriority="20"
    doMultiWigChild

    parentTrack="${hubName}_ATCG"
    trackName="C"
    fileName="varscanParsed_C.bw"
    trackColor=${Ccolor}
    trackPriority="20"
    doMultiWigChild

    parentTrack="${hubName}_ATCG"
    trackName="G"
    fileName="varscanParsed_G.bw"
    trackColor=${Gcolor}
    trackPriority="20"
    doMultiWigChild
    
echo 'Making overlay track for :'
    
echo ' |-- varscanParsed_allcounts.bw'
echo ' |-- varscanParsed_allcountsQfiltered.bw'
echo ' `-- varscanParsed_allcountsQfilteredConsensus.bw'

    longLabel="${hubName} basewise depth : all RED , Q30filt BLUE , Q30 ref allele GREEN"
    trackName="${hubName}_mapCounts"
    overlayType="solidOverlay"
    windowingFunction="maximum"
    visibility="full"
    doMultiWigParent
    
    allcolor='255,74,179'
    allQcolor='0,0,200'
    allQCcolor='62,176,145'

    
    parentTrack="${hubName}_mapCounts"
    trackName="all"
    fileName="varscanParsed_allcounts.bw"
    trackColor=${allcolor}
    trackPriority="100"
    doMultiWigChild

    parentTrack="${hubName}_mapCounts"
    trackName="Qfiltered"
    fileName="varscanParsed_allcountsQfiltered.bw"
    trackColor=${allQcolor}
    trackPriority="101"
    doMultiWigChild

    parentTrack="${hubName}_mapCounts"
    trackName="Qfilt_refBase"
    fileName="varscanParsed_allcountsQfilteredConsensus.bw"
    trackColor=${allQCcolor}
    trackPriority="102"
    doMultiWigChild


echo 'Making overlay track for :'

echo ' |-- varscanParsed_DEL_approximate.bw'
echo ' `-- varscanParsed_INS_approximate.bw'
    
    longLabel="${hubName} indels : INS yellow , DEL grey"
    trackName="${hubName}_INDEL"
    overlayType="transparentOverlay"
    windowingFunction="maximum"
    visibility="full"
    doMultiWigParent
    
    INScolor='255,211,0'
    DELcolor='100,100,100'
    
    parentTrack="${hubName}_INDEL"
    trackName="ins"
    fileName="varscanParsed_INS_approximate.bw"
    trackColor=${INScolor}
    trackPriority="10"
    doMultiWigChild
    
    parentTrack="${hubName}_INDEL"
    trackName="del"
    fileName="varscanParsed_DEL_approximate.bw"
    trackColor=${DELcolor}
    trackPriority="10"
    doMultiWigChild  

# -----------------------------------
   
    echo ""
    echo "Generated data hub :" > hub_address.txt
    
    echo 1 >> "/dev/stderr"
    tempServer=$(echo "${server}" | sed 's/\/$//')
    echo "'"${tempServer}"'">> "/dev/stderr"
    echo 2 >> "/dev/stderr"
    tempPath="${tempServer}"$(echo "/"${serverpath}/${hubName}"/hub.txt" | sed 's/\/\/*/\//g')
    
    echo "${tempPath}" >> hub_address.txt
    echo >> hub_address.txt  
   
    echo 'How to load this hub to UCSC : http://userweb.molbiol.ox.ac.uk/public/telenius/CaptureCompendium/CCseqBasic/DOCS/HUBtutorial_AllGroups_160813.pdf' >> hub_address.txt
    
    cat hub_address.txt



