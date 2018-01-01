* create an xlsx file with a simple datacube.

* open file.
GET
  FILE='c:\temp\notes_without_comments.sav'.
DATASET NAME basicdata WINDOW=FRONT.


* prepping files..

* clean anonymous notes.
if action>0 & missing(uid) uid=-1.

* add geo info.
GET
  FILE='c:\temp\joined_ids.sav'.
DATASET NAME geo WINDOW=FRONT.
match files
/file=*
/keep=note_id
geoitem.
EXECUTE.
DATASET ACTIVATE basicdata.
MATCH FILES /FILE=*
  /TABLE='geo'
  /BY note_id.
EXECUTE.
dataset close geo.

* add apps info.
GET
  FILE='c:\temp\notes_from_apps.sav'.
DATASET NAME apps WINDOW=FRONT.
EXECUTE.
DATASET ACTIVATE basicdata.
MATCH FILES /FILE=*
  /TABLE='apps'
  /BY note_id.
EXECUTE.
dataset close apps.


* get interaction info..
GET
  FILE='c:\temp\interaction.sav'.
DATASET NAME interaction WINDOW=FRONT.
EXECUTE.
DATASET ACTIVATE basicdata.
MATCH FILES /FILE=*
  /TABLE='interaction'
  /BY note_id.
EXECUTE.
dataset close interaction.

* first closed.
if note_id=lag(note_id) first_closing=0.
if lag(note_id)=note_id & action=2 first_closing=1.
if lag(note_id)=note_id & (lag(first_closing)>0)  first_closing=lag(first_closing)+1.
EXECUTE.
recode first_closing (2 thru highest=0).
EXECUTE.

* named or anonymous contributor.
if action = 1 & uid=-1 anonymous_notes=1.
if action = 1 & uid~=-1 anonymous_notes=0.

* add OP (original poster) to all records.
DATASET ACTIVATE basicdata.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=note_id
  /uid_OP=FIRST(uid).

* closed by someone else.
if uid_OP=uid & first_closing=1 selfclosed=1.
if uid_OP~=uid & first_closing=1 selfclosed=0.

*** compute time till first closing.
* identify closed notes.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=note_id
  /closed_at_least_once=MAX(first_closing).

* add opening date to all records


AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=note_id
  /opening_time=FIRST(time).


* compute timediff.
if first_closing=1 days_to_close=DATEDIFF(time,opening_time,"days").

* app-cat.
compute appcat=0.
if mapsme=1 appcat=1.
if navmii=1 appcat=2.
if streetcomplete=1 appcat=3.
value labels appcat
0 'no clear app'
1 'Maps.me'
2 'Navmii'
3 'StreetComplete'.



DATASET DECLARE aggregatecube.
AGGREGATE
  /OUTFILE='aggregatecube'
  /BREAK=note_id geoitem opening_time
  /year=FIRST(year) 
  /month=FIRST(month) 
  /day=FIRST(day) 
  /anonymous_note=MAX(anonymous_notes) 
  /selfclosed=MAX(selfclosed) 
  /closed_at_least_once=MAX(closed_at_least_once) 
  /days_to_close=MAX(days_to_close)
  /appcat=min(appcat)
  /interaction=max(interaction).
DATASET ACTIVATE aggregatecube.

recode interaction (sysmis=3).
add value labels interaction 3 'not relevant for interaction'.
* AFTER AGGREGATE.
* remove diff if not old enough
* adapt to date of the dump.
COMPUTE age=DATEDIFF(DATE.DMY(24,11,2017),opening_time,"days").
EXECUTE.
* check open notes

if days_to_close <= 90 closing_type=1.
if days_to_close > 90 closing_type=2.
if missing(days_to_close) closing_type=3.
if DATEDIFF(DATE.DMY(24,11,2017),opening_time,"days")<=90 closing_type=4.


value labels closing_type
1 'closed within 90 days'
2 'closed after more than 90 days'
3 'still open'
4 'too soon to tell'.
* aanmaak kubus:
annoniem/niet annoniem
tijd tot sluiten
binnen drie maand / langer dan drie maand / nog steeds open / nog geen drie maand oud
afgesloten door iemand anders


recode selfclosed (missing=2).

* remove notes without a decent opening record.
FILTER OFF.
USE ALL.
SELECT IF (anonymous_note > -1).
EXECUTE.


DATASET ACTIVATE aggregatecube.
DATASET DECLARE notecube.
AGGREGATE
  /OUTFILE='notecube'
  /BREAK=geoitem year month anonymous_note selfclosed closing_type appcat
  /cube_notes=N.
dataset activate notecube.

* TODO define missing area in Swing.

string period (a8).
compute period=concat("M",ltrim(string(month,f2.0)),"Y",string(year,f4.0)).
EXECUTE.
delete variables year month.
string geolevel (a7).
compute geolevel="regions".
EXECUTE.

alter type geoitem (f15.0).
alter type geoitem (a15).


rename variables (anonymous_note
selfclosed
closing_type=
cn_anonymous_note
cn_selfclosed
cn_closing_type).


FILTER OFF.
USE ALL.
SELECT IF (geoitem~="").
EXECUTE.
compute geoitem=ltrim(rtrim(geoitem)).


SAVE TRANSLATE OUTFILE='D:\OSM\notes\processed_data\simple_cube.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.

dataset close aggregatecube.
dataset close basicdata.

