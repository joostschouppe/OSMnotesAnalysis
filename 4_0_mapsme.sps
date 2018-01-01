* open sav met comments.


GET
  FILE='C:\temp\notes_and_comments.sav'.
DATASET NAME DataSet1 WINDOW=FRONT.

FILTER OFF.
USE ALL.
SELECT IF (action=1).
EXECUTE.

*#mapsme.
if CHAR.INDEX(V1,"#mapsme")>0 | CHAR.INDEX(V1," MAPS.ME ")>0 & action=1 mapsme=1.
if CHAR.INDEX(V1,"StreetComplete")>0 & action=1 streetcomplete=1.
if CHAR.INDEX(V1,"Navmii")>0 & action=1 navmii=1.
EXECUTE.

DATASET DECLARE apps.
AGGREGATE
  /OUTFILE='apps'
  /BREAK=note_id
  /navmii=MAX(navmii)
  /streetcomplete=MAX(streetcomplete)
  /mapsme=MAX(mapsme).
dataset activate apps.

FILTER OFF.
USE ALL.
SELECT IF (max(navmii,streetcomplete,mapsme)=1).
EXECUTE.


SAVE OUTFILE='C:\temp\notes_from_apps.sav'
  /COMPRESSED.
