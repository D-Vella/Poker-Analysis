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

** Possible Bug: **
It seems suspicious that my hands count equals my player count. (Fixed - added to learning points)

Players modelled as a dict keyed by name produced one wide row per hand; correct shape is one row per player per hand (long, not wide) — wide tables break both row counts and Parquet. Need to fix at source.
