* creates an xlsx file with some absolute basic statistics.

* open file.

GET
  FILE='c:\temp\notes_without_comments.sav'.
DATASET NAME basicdata WINDOW=FRONT.


* if there's an action but no user id, set user id to -1.
if action>0 & missing(uid) uid=-1.


* basics.
DATASET DECLARE basics.
AGGREGATE
  /OUTFILE='basics'
  /PRESORTED
  /BREAK=note_id
  /lat=first(lat)
  /lon=first(lon)
  /time_opened=FIRST(time) 
  /year_opened=FIRST(year) 
  /month_opened=FIRST(month) 
  /uid_opened=FIRST(uid).
dataset activate basics.


GET
  FILE='D:\OSM\notes\processed_data\joined_ids.sav'.
DATASET NAME geo WINDOW=FRONT.


DATASET ACTIVATE basics.
MATCH FILES /FILE=*
  /TABLE='geo'
  /RENAME (lat lon = d0 d1) 
  /BY note_id
  /DROP= d0 d1.
EXECUTE.

dataset close geo.



dataset activate basics.
DATASET DECLARE firstset.
AGGREGATE
  /OUTFILE='firstset'
  /BREAK=year_opened month_opened geoitem
  /notes_number=N.
dataset activate firstset.

DATASET ACTIVATE firstset.
FILTER OFF.
USE ALL.
SELECT IF (year_opened > 0).
EXECUTE.

string period (a8).
compute period=concat("M",ltrim(string(month_opened,f2.0)),"Y",string(year_opened,f4.0)).
EXECUTE.
delete variables year_opened month_opened.
string geolevel (a7).
compute geolevel="regions".
EXECUTE.

alter type geoitem (f15.0).
alter type geoitem (a15).

DATASET DECLARE world.
AGGREGATE
  /OUTFILE='world'
  /BREAK=period geolevel
  /notes_number=SUM(notes_number).
dataset activate world.
string geoitem (a15).
compute geoitem="world".
compute geolevel="world".
EXECUTE.

DATASET ACTIVATE world.
ADD FILES /FILE=*
  /FILE='firstset'.
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (geoitem~="").
EXECUTE.
dataset close firstset.
compute geoitem=ltrim(rtrim(geoitem)).

SAVE TRANSLATE OUTFILE='D:\OSM\notes\processed_data\firstset.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.


dataset close basics.
dataset close basicdata.
