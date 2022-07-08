#!/bin/bash
# Based on https://wiki.openstreetmap.org/wiki/Upload.py#Multi-part_uploads.
# Directory where data are stored locally.
export DIRECTORY=
# OsmChange file name without extension.
input=latvia-diff
# OSM user name and password.
ident="-u latvia-bot -p "

cd $DIRECTORY

# Create comment file.
echo "Updated addresses in Latvia." > latvia-diff.comment

# Split OsmChange file in pieces no larger than 10000 elements (changeset limit).
python split.py "$input.osc" 10000 || exit -1

# Delete bounds element from the 1st OsmChange file.
xml ed -d '//osmChange/modify/bounds' latvia-diff-part1.osc > latvia-diff-part1-edited.osc
mv latvia-diff-part1-edited.osc latvia-diff-part1.osc

# Number of parts as count of *-part*.osc files (https://askubuntu.com/a/454568).
parts=`find -maxdepth 1 -type f -name "*-part*.osc" -printf x | wc -c`

# Upload changes. New changeset for every 10000 elements.
for num in `seq 1 $parts`; do
        python upload.py $ident -c yes -y "Valsts adrešu reģistra informācijas sistēmas atvērtie dati" "$input-part$num.osc" || exit -1

        for rnum in `seq $num $parts`; do
                path/to/python2/python diffpatch.py "$input-part$num.diff.xml" "$input-part$rnum.osc" || exit -1
                mv "$input-part$rnum.osc.diffed" "$input-part$rnum.osc" || exit -1
        done
done

# Delete OsmChange and comment files.
#rm *.osc
#rm *.comment
