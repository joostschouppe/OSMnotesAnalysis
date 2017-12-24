* TODO: get multiline comments into one row.

GET DATA  /TYPE=TXT
  /FILE="c:\temp\planet-notes-171125.osn"
  /ENCODING='UTF-8'
  /DELCASE=LINE
  /DELIMITERS=""
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=1
  /IMPORTCASE=ALL
  /VARIABLES=
  V1 A700.
CACHE.
EXECUTE.
DATASET NAME DataSet1 WINDOW=FRONT.


* find begin
* find lat long
* find action
* find contributor

* try to get into one row per action.

* identify the start row of notes.
if char.substr(v1,1,9)='<note id=' note=1.
* make a variable with the note id.
if note=1 note_id=number(char.substr(v1,11,char.index(char.substr(v1,11),'"')-1),f20.0).
* find the latitude.
if note=1 lat=number(replace(
char.substr(v1,
char.index(v1,' lat="')+6,
char.index(char.substr(v1,char.index(v1,' lat="')+6),'"')-1),
".",","),
f18.8).
* find the longitude.
if note=1 lon=number(replace(
char.substr(v1,
char.index(v1,' lon="')+6,
char.index(char.substr(v1,char.index(v1,' lon="')+6),'"')-1),
".",","),
f18.8).

* find the action.
if char.index(v1,'<comment action="opened"')>0 action=1.
if char.index(v1,'<comment action="closed"')>0 action=2.
if char.index(v1,'<comment action="reopened"')>0 action=3.
if char.index(v1,'<comment action="commented"')>0 action=4.

value labels action
1 'opened'
2 'closed'
3 'reopened'
4 'commented'.

* find the timestamp.
string timestamp (a20).
if action>0 timestamp=
char.substr(v1,
char.index(v1,' timestamp="')+12,
char.index(char.substr(v1,char.index(v1,' timestamp="')+12),'"')-1).
* find the uid.
if action>0& char.index(v1,' user="')>0 uid=number(
char.substr(v1,
char.index(v1,' uid="')+6,
char.index(char.substr(v1,char.index(v1,' uid="')+6),'"')-1),
f18.0).

* find the username.
string user (a127).
if action>0 & char.index(v1,' user="')>0 user=
char.substr(v1,
char.index(v1,' user="')+7,
char.index(char.substr(v1,char.index(v1,' user="')+7),'"')-1).


* add the noteID to all the rows related to the note.
if missing(note) note_id=lag(note_id).

* make some time variables.
compute year=number(char.substr(timestamp,1,4),f4.0).
compute month=number(char.substr(timestamp,6,2),f2.0).
compute day=number(char.substr(timestamp,9,2),f2.0).
compute hour=number(char.substr(timestamp,12,2),f2.0).
compute minute=number(char.substr(timestamp,15,2),f2.0).
compute second=number(char.substr(timestamp,18,2),f2.0).

*create a proper time variable.
COMPUTE  time=DATE.DMY(day, month, year) + TIME.HMS(hour, minute, second).
VARIABLE LEVEL  time (SCALE).
FORMATS  time (DATETIME20).
VARIABLE WIDTH  time(20).

* pretend like all the records with an action also had  a comment.
if action>0 commented=1.
* remove the pretend comment in case there is no comment on its record.
if action>0 & char.index(v1,'></comment>')>0 commented=0.

* make variables pretty.
alter type year (f4.0).
alter type month day hour minute second (f2.0).
EXECUTE.

* keep only the main records (actions and comments). Note that notes with hard breaks in the text lose most of the comment.
FILTER OFF.
USE ALL.
SELECT IF (note > 0 | action > 0).
EXECUTE.

SAVE OUTFILE='c:\temp\notes_and_comments.sav'
  /COMPRESSED.
delete variables v1.
SAVE OUTFILE='c:\temp\notes_without_comments.sav'
  /COMPRESSED.



