# Database names and content

Bellow are all the discovered contents existent in some tables.
Results will be shown by database followed by table.
Each table will be described using the following syntax:
 | | | |
 | :--- | :--- | :---: |
 | status | whether the table is under investigation or fully investigated | ON GOING, FINISHED |
 | content | what information resides in the table | |
 | certainty | whether the content and column descriptions are 100% accurate | YES, NO |

## trainingcache2.db (9.4.11.312687073)

This database is used to store inputs from GBoard. It detects individual key presses, deleted words, swiped words.

### SQLITE_SEQUENCE
 * **status:** ON GOING
 * **content:** Gathers all tables which were updated at least once.
 * **certainty:** NO

#### columns
 * **NAME:** table's name
 * **SEQ:** amount of content in the table


### D_TABLE
 * **status:** ON GOING
 * **content:** Deleted words
 * **certainty:** YES

#### columns
 * **_ID:** internal id
 * **_TIMESTAMP:** time elapsed since the Unix epoch (ms)
 * **_PAYLOAD:** protobuf data
 * **F1:** ?
 * **F2:** global typed sequence
 * **F3:** negative cumulative fold of F4
 * **F4:** string size
 * **F5:** deleted string
 * **F6:** ?


### TF_TABLE
 * **status:** ON GOING
 * **content:** Typed words
 * **certainty:** YES

#### columns
 * **_ID:** internal id
 * **_TIMESTAMP:** time elapsed since the Unix epoch (ms)
 * **_PAYLOAD:** protobuf data
 * **F1:** ?
 * **F2:** global typed sequence
 * **F3:** typed string
 * **F4:** ?

### TM_TABLE
 * **status:** ON GOING
 * **content:** White characters and emojis from TF_TABLE
 * **certainty:** YES

#### columns
 * **_ID:** internal id
 * **_TIMESTAMP:** time elapsed since the Unix epoch (ms)
 * **_PAYLOAD:** protobuf data
 * **F1:** ?
 * **F2:** global typed sequence
 * **F3:** ?

## gboard_clipboard.db (9.4.11.312687073-10.5.03.367007960)

### CLIPS
 * **status:** ON GOING
 * **content:** Copied items to the clipboard
 * **certainty:** YES

#### columns
 * **_ID:** internal id
 * **TEXT:** copied text
 * **HTML_TEXT:** html representation of the copied text
 * **ITEM_TYPE:** ?
 * **ENTITY_TYPE:** ?
 * **TIMESTAMP:** time elapsed since the Unix epoch (ms)
 * **URI:** uri of the copied document
 * **GROUP_ID:** ?
