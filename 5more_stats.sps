* creates an xlsx file with some more statistics.

* define anonymous and named notes.
* makes sensible statistics about the time it takes to close notes.


* open file.

GET
  FILE='c:\temp\notes_without_comments.sav'.
DATASET NAME basicdata WINDOW=FRONT.


* if there's an action but no user id, set user id to -1.
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
  /days_to_close=MAX(days_to_close).
DATASET ACTIVATE aggregatecube.


* AFTER AGGREGATE.
* remove diff if not old enough
* adapt to date of the dump.
COMPUTE age=DATEDIFF(DATE.DMY(24,11,2017),opening_time,"days").
EXECUTE.
* check open notes.
recode days_to_close
(0=1)
(1 thru 6=2)
(7 thru 29=3)
(30 thru 89=4)
(90 thru 179=5)
(180 thru 364=6)
(365 thru highest=7) into time_till_close_cat.
value labels time_till_close_cat
1 'less than a day'
2 'at least a day, less than a week'
3 'at least a week, less than a month'
4 'at least a month, less than three months'
5 'at least three months, less than six months'
6 'at least six months, less than a year'
7 'at least a year'.

if time_till_close_cat = 1 & age>0 closed_in_0 =1.
if age>0 closeable_in_0 =1.
if time_till_close_cat <= 2 & age>6 closed_in_6 =1.
if age>6 closeable_in_6 =1.
if time_till_close_cat <= 3 & age>29 closed_in_29 =1.
if age>29 closeable_in_29 =1.
if time_till_close_cat <= 4 & age>89 closed_in_89 =1.
if age>89 closeable_in_89 =1.
if time_till_close_cat <= 5 & age>179 closed_in_179 =1.
if age>179 closeable_in_179 =1.
if time_till_close_cat <= 6 & age>364 closed_in_364 =1.
if age>364 closeable_in_364 =1.
EXECUTE.


DATASET ACTIVATE aggregatecube.
DATASET DECLARE excel.
AGGREGATE
  /OUTFILE='excel'
  /BREAK=geoitem year month
  /anonymous_note=SUM(anonymous_note) 
  /selfclosed=SUM(selfclosed) 
  /closed_in_0=SUM(closed_in_0) 
  /closeable_in_0=SUM(closeable_in_0) 
  /closed_in_6=SUM(closed_in_6) 
  /closeable_in_6=SUM(closeable_in_6) 
  /closed_in_29=SUM(closed_in_29) 
  /closeable_in_29=SUM(closeable_in_29) 
  /closed_in_89=SUM(closed_in_89) 
  /closeable_in_89=SUM(closeable_in_89) 
  /closed_in_179=SUM(closed_in_179) 
  /closeable_in_179=SUM(closeable_in_179) 
  /closed_in_364=SUM(closed_in_364)
  /closeable_in_364=SUM(closeable_in_364) .

DATASET ACTIVATE excel.
FILTER OFF.
USE ALL.
SELECT IF (year > 0).
EXECUTE.

string period (a8).
compute period=concat("M",ltrim(string(month,f2.0)),"Y",string(year,f4.0)).
EXECUTE.
delete variables year month.
string geolevel (a7).
compute geolevel="regions".
EXECUTE.

alter type geoitem (f15.0).
alter type geoitem (a15).

DATASET DECLARE world.
AGGREGATE
  /OUTFILE='world'
  /BREAK=period geolevel
  /anonymous_note=SUM(anonymous_note) 
  /selfclosed=SUM(selfclosed) 
  /closed_in_0=SUM(closed_in_0) 
  /closeable_in_0=SUM(closeable_in_0) 
  /closed_in_6=SUM(closed_in_6) 
  /closeable_in_6=SUM(closeable_in_6) 
  /closed_in_29=SUM(closed_in_29) 
  /closeable_in_29=SUM(closeable_in_29) 
  /closed_in_89=SUM(closed_in_89) 
  /closeable_in_89=SUM(closeable_in_89) 
  /closed_in_179=SUM(closed_in_179) 
  /closeable_in_179=SUM(closeable_in_179) 
  /closed_in_364=SUM(closed_in_364)
  /closeable_in_364=SUM(closeable_in_364) .
dataset activate world.
string geoitem (a15).
compute geoitem="world".
compute geolevel="world".
EXECUTE.


ADD FILES /FILE=*
  /FILE='excel'.
EXECUTE.

FILTER OFF.
USE ALL.
SELECT IF (geoitem~="").
EXECUTE.
compute geoitem=ltrim(rtrim(geoitem)).

SAVE TRANSLATE OUTFILE='D:\OSM\notes\processed_data\more_stats.xlsx'
  /TYPE=XLS
  /VERSION=12
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.


dataset close aggregatecube.
dataset close basicdata.
dataset close excel.