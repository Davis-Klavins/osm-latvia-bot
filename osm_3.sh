#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of OSM user latvia-bot.
export OSMPASSWORD=

cd $DIRECTORY

# Delete bounds element (3rd line) from the osmChange file.
sed -i '4d' latvia-diff.osc

# Upload changes (https://wiki.openstreetmap.org/wiki/Upload.py).
# python upload.py -u latvia-bot -p $OSMPASSWORD -c yes -m "Comment." -y "Valsts adrešu reģistra informācijas sistēmas atvērtie dati" $DIRECTORY/latvia-diff.osc
