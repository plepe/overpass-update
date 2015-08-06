#!/bin/bash

cd
mkdir db-new
DB_DIR="/home/overpass/db-new"
PLANET="/home/overpass/planet-latest.osm.bz2"
TIMESTAMP="/home/overpass/last_planet_date"

LAST_OSMDATE=`cat ${TIMESTAMP}`

#echo $LAST_TIMESTAMP
#
#exit
date

while : ; do
# check file date on the server
  OSMDATE=`curl -I http://planet.openstreetmap.org/planet/planet-latest.osm.bz2  | grep -e '^Location:' | sed 's/^.*planet-\(.*\)\.osm\.bz2.*$/\1/'`
  echo "Newest planet file date: ${OSMDATE}, current: ${LAST_OSMDATE}"

# if this is a new file, continue with the rest of the code
  [[ "${LAST_OSMDATE}" -ge "${OSMDATE}" ]] || break

# otherwise wait for half an hour and try again
  sleep 900
done

rm $PLANET
time wget --progress=dot:giga -O $PLANET http://planet.openstreetmap.org/planet/planet-latest.osm.bz2
touch -r planet-latest.osm.bz2 last_planet_timestamp

date

# While importing increase age of planet-import-complete
echo -e '#!/bin/sh\ntouch --date "-4 month" /tiles/planet-import-complete' > /etc/cron.hourly/planet-import-complete

time osm-3s_v0.7.51/src/bin/init_osm3s.sh $PLANET $DB_DIR $EXEC_DIR --meta

if [ "$?" != "0" ] ; then
  date
  echo "An error occured when importing data"
  exit 1
fi
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
echo ${OSMDATE} > ${TIMESTAMP}

# Done -> decrease age of planet-import-complete
echo -e '#!/bin/sh\ntouch --date "-3 month" /tiles/planet-import-complete' > /etc/cron.hourly/planet-import-complete

#touch /tiles/planet-import-complete
