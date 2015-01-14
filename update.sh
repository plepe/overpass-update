#!/bin/bash

cd
mkdir db-new
DB_DIR="/home/overpass/db-new"
PLANET="/home/overpass/planet-latest.osm.bz2"

date

rm $PLANET
time wget --progress=dot:giga -O $PLANET http://planet.openstreetmap.org/planet/planet-latest.osm.bz2

date

time osm-3s_v0.7.51/src/bin/init_osm3s.sh $PLANET $DB_DIR $EXEC_DIR --meta

date

rm $PLANET

osm3s_query --progress --rules --db-dir=$DB_DIR < $EXEC_DIR/db/rules/areas_low_ram.osm3s

if [ "$?" != "0" ] ; then
  date
  echo "An error occured when creating areas"
  exit 1
fi

date

mv db-new/* db/

date

#touch /tiles/planet-import-complete
