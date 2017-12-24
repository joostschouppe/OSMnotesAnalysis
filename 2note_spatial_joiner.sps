* open file.

GET
  FILE='C:\temp\notes_without_comments.sav'.
DATASET NAME basicdata WINDOW=FRONT.

* geocoding time.

* if it's the first time, geocode all the data.
* if it is the second time, merge the new data with the geocoded data, then update the list of geoceded data.

DATASET DECLARE geocode.
AGGREGATE
  /OUTFILE='geocode'
  /PRESORTED
  /BREAK=note_id
  /lat=first(lat)
  /lon=first(lon).
DATASET ACTIVATE geocode.

SAVE TRANSLATE OUTFILE='D:\OSM\notes\tests\alldata.csv'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.

* spatial join performed in qgis.

GET DATA  /TYPE=TXT
  /FILE="C:\temp\joined.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES=
  note_id F3.0
  lat F11.0
  lon F12.0
  ADMIN_LEVE F1.0
  BOUNDARY A14
  CITY_KEY F8.0
  ID F7.0
  NAME A136
  REGION_KEY F12.0
  idNUM F7.0.
CACHE.
EXECUTE.
DATASET NAME output WINDOW=FRONT.
match files
/file=*
/keep= note_id id.
EXECUTE.
rename variables id=geoitem.




DATASET ACTIVATE geocode.
MATCH FILES /FILE=*
  /TABLE='output'
  /BY note_id.
EXECUTE.


SAVE OUTFILE='C:\temp\joined_ids.sav'
  /COMPRESSED.

dataset close output.
dataset activate basicdata.
dataset close geocode.
