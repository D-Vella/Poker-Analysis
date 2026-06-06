I have found the definition of the PHH format (here)[https://phh.readthedocs.io/en/stable/]

I have tested the parsing code against the first hand but this leaves gaps:
* I need to check the board cards function against a hand that had them (Done)
* Actions need breaking out into columns. (Done)

winnings key absent on showdown hands; sm = show/muck, ???? = mucked (cards hidden); use .get() not [...]; deciding the winner needs a hand evaluator, deferred unless a stat requires it.

Both blinds are posted outside the actions list, in blinds_or_straddles — not a voluntary action; VPIP must exclude them.

Call amounts not stored in PHH; deriving them needs full betting-state tracking; not needed for action-based preflop stats. Leave as None unless a pot/win-rate stat is added.

In the event of an unknown verb the parser will print what it hit.

tomllib will read the whole file of PHH natively and the "[1]" becomes the index for each hand in a given file.