I have found the definition of the PHH format (here)[https://phh.readthedocs.io/en/stable/]

I have tested the parsing code against the first hand but this leaves gaps:
* I need to check the board cards function against a hand that had them (Done)
* Actions need breaking out into columns. (Done)

winnings key absent on showdown hands; sm = show/muck, ???? = mucked (cards hidden); use .get() not [...]; deciding the winner needs a hand evaluator, deferred unless a stat requires it.

Both blinds are posted outside the actions list, in blinds_or_straddles — not a voluntary action; VPIP must exclude them.

Call amounts not stored in PHH; deriving them needs full betting-state tracking; not needed for action-based preflop stats. Leave as None unless a pot/win-rate stat is added.

In the event of an unknown verb the parser will print what it hit.

tomllib will read the whole file of PHH natively and the "[1]" becomes the index for each hand in a given file.

I have written the 3 outputs for 1000 hand (one source file) into parquet and csv
|name|row count|csv size|parquet size|
|---|---|---|---|
|hands|1000|51 KB|18 KB|
|players|1000|563 KB|346 KB|
|actions|10985|319 KB|32 KB|

Doing larger test of 1 folder of data  (391 files):

tqdm reports about 9 files per second. No unknown firing.

|name|row count|csv size|parquet size|
|---|---|---|---|
|hands|389,834|19,420 KB|4,673 KB|
|players|2,273,209|108,374 KB|14,251 KB|
|actions|4,146,645|120,491 KB|10,641 KB|

**Bug #0 FOUND:**
It seems suspicious that my hands count equals my player count. (Fixed - added to learning points)

Players modelled as a dict keyed by name produced one wide row per hand; correct shape is one row per player per hand (long, not wide) — wide tables break both row counts and Parquet. Need to fix at source.

Doing a complete run of all of the data (21,782 files 21.6 M hands)

**BUG #1 FOUND:**
Issue found where I get a key error for 'hand'
I need to put better error logging for these errors. Need to show the file name and the TOML index. (Done)
Also need some defensive mesasures. (Done)

**BUG #2 Found:**
Serious memory consumption. Implementing a batch and flush methodology.

Also changing the schema and putting in schema enforcement on write. Things Changed:
* Hand_Id is now a string everywhere.
* Added a small_blind and big_blind column to hands.

tqdm is reporting between 8-10 files per second. This is likely due to disk caching.
Full run total file count is 21,782.
Full run completed in 1:10:35 with a FILE_BATCH_SIZE = 250
> Total files processed: 21,782. Total hands skipped due to errors: 133.
This is an error rate of 0.00061%

|name|row count|parquet size|
|---|---|---|---|
|hands|389,834|4,673 KB|
|players|2,273,209|14,251 KB|
|actions|4,146,645|10,641 KB|

Duck DB and DBT setup:
Installed the dbt-duckdb items. Note that the profile is created in my user directory and not the projects directory.

I need to build the duck DB persistant database. (Done)

## Schema anlaysis for Silver layer transformations.

### Observations:
* Confirmed that the player ID is consistant across hands.
* Check the referential integreity of the data.

### Changes to make in DBT:
* Rebuild the Hand_ID to be pure intergers for compression.
    * Deffered until after phase 6 as a benchmarking test
* May rebuild the player ID to an int as well for the same reason.
    * Deffered until after phase 6 as a benchmarking test

### Changes to make in Bronze Ingestion:
* Map the actions to the player ID. Right now the `actions` table only has the player number like "p1". It needs the actual player_ID from the `players` table.
* Add the datetime field to the `hand` table entry to enable time series analysis.