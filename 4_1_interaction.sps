
* open file.
GET
  FILE='c:\temp\notes_without_comments.sav'.
DATASET NAME basicdata WINDOW=FRONT.


* named or anonymous contributor.
if action = 1 & uid=-1 anonymous_notes=1.
if action = 1 & uid~=-1 anonymous_notes=0.

* add OP (original poster) to all records.
DATASET ACTIVATE basicdata.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=note_id
  /uid_OP=FIRST(uid).


* prepping files..

* clean anonymous notes.
if action>0 & missing(uid) uid=-1.


*kans op een verdere actie van OP indien er een comment volgt
* selecteer notes met minstens één comment.
* die niet anoniem zijn.
if action=4 temp=1.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=note_id
  /commented_note=MAX(temp)
  /anonymous_note=max(anonymous_notes).
FILTER OFF.
USE ALL.
SELECT IF (commented_note=1 & anonymous_note =0 & (uid~=-1 | missing(uid))).
EXECUTE.
delete variables temp.

* loop through to check.
if $casenum=1 | note_id~=lag(note_id) startchecking=1.
if action=1 startchecking=1.
if lag(startchecking)=1 & ~(action=4 & uid~=uid_OP) startchecking=1.
if lag(startchecking)=1 & action=4 & uid~=uid_OP startchecking=2.
if lag(startchecking)=2 & uid~=uid_OP startchecking=2.
if lag(startchecking)=2 & uid=uid_OP startchecking=3.
EXECUTE.

DATASET DECLARE interaction.
AGGREGATE
  /OUTFILE='interaction'
  /BREAK=note_id
  /interaction=MAX(startchecking).
DATASET ACTIVATE interaction.
FILTER OFF.
USE ALL.
SELECT IF (interaction>1).
EXECUTE.
recode interaction (2=0) (3=1).
EXECUTE.
value labels interaction
0 'relevant for interaction, but none seen'
1 'interaction seen'.



SAVE OUTFILE='C:\temp\interaction.sav'
  /COMPRESSED.

dataset activate basicdata.
dataset close interaction.

