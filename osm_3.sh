#!/bin/bash
# Based on https://wiki.openstreetmap.org/wiki/Upload.py#Multi-part_uploads.
# Directory where data are stored locally.
export DIRECTORY=
# OsmChange file name without extension.
input=latvia-diff
# OSM user name and password.
ident="-u latvia-bot -p "
# Zulip bot e-mail address and API key.
zulip="latvia-bot@osmlatvija.zulipchat.com:"
# Zulip message text.
text="content="
# Path to ways_relations_del.csv.
file_path="ways_relations_del.csv"

cd $DIRECTORY

# Create comment file.
echo "Updated addresses in Latvia." > latvia-diff.comment

# Split OsmChange file in pieces no larger than 10 000 elements (changeset limit).
py osm-latvia-bot/upload.py/split.py "$input.osc" 10000 || exit -1

# Delete bounds element from the 1st OsmChange file.
xml ed -d '//osmChange/modify/bounds' latvia-diff-part1.osc > latvia-diff-part1-edited.osc
mv latvia-diff-part1-edited.osc latvia-diff-part1.osc

# Number of parts as count of *-part*.osc files (https://askubuntu.com/a/454568).
parts=`find -maxdepth 1 -type f -name "*-part*.osc" -printf x | wc -c`

# Upload changes. Separate changeset for every 10 000 elements.
for num in `seq 1 $parts`; do
        py osm-latvia-bot/upload.py/upload.py $ident -c yes -t -y "Valsts adrešu reģistra informācijas sistēmas atvērtie dati" "$input-part$num.osc" || exit -1

        for rnum in `seq $num $parts`; do
                py osm-latvia-bot/upload.py/diffpatch.py "$input-part$num.diff.xml" "$input-part$rnum.osc" || exit -1
                mv "$input-part$rnum.osc.diffed" "$input-part$rnum.osc" || exit -1
        done
done

# Concatenate Zulip message text and ways_relations_del.csv contents into a variable.
message="${text} $(cat ${file_path})"

# Post message to Zulip.
if ! [ -s $file_path ];then
    echo -e "No deleted ways and relations."
    exit
fi

curl -X POST https://osmlatvija.zulipchat.com/api/v1/messages \
    -u $zulip \
    --data-urlencode type=stream \
    --data-urlencode 'to="adreses"' \
    --data-urlencode topic="Deleted ways and relations by latvia-bot to be reviewed" \
    --data-urlencode "${message}"

# Delete OsmChange and comment files and ways_relations_del.csv.
#rm *.osc
#rm *.comment
#rm *.diff.xml
#rm ways_relations_del.csv
