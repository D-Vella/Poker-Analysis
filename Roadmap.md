# Poker Hand Analytics — Project Roadmap

> A modern-data-stack learning pipeline that ingests poker hand histories, models them, and computes the player statistics that commercial trackers struggle to produce at scale.
> Built spare-time. Each phase leaves the project in a working state and teaches one new piece of the stack.

---

## What This Project Is (and Isn't)

**It is:** an offline *analysis* pipeline. Raw hand-history files in one end → parsed, stored as Parquet, modelled in dbt, queried in DuckDB, displayed in Streamlit.

**It isn't:** a poker tracker. Trackers are hard because they run a real-time HUD (heads-up display) that refreshes stats sub-second *while you play and new hands stream in*, on a row-oriented database sitting on a laptop. Each hand explodes into dozens of action rows, so "5 million hands" is really 50–100 million rows, and the row store bogs down. You have removed the hard part by dropping the real-time requirement. What's left — scan lots of rows, group, aggregate — is exactly what a columnar engine (DuckDB) is built for. The whole point of this project is to *feel* that difference.

**Primary dataset:** the PHH dataset (University of Toronto computer poker group, on Zenodo). ~21.6M no-limit hold'em hands, CC-BY 4.0, structured "PHH" hand-history format with full betting action. Credit it if you publish anything.

**Why not the others:** the famous IRC database (10M+ hands) lacks per-street bet amounts, which kills the stats you want. The Kaggle "1M hands" set is hand-rank classification — no betting at all. Avoid both.

---

## How To Use This Roadmap

Same rules as your other projects: each phase is self-contained, sized for one to three sessions of 30–90 minutes, and always leaves the project working. Check the exit criteria before moving on. Log discoveries in **Field Notes** as you go.

One difference from your usual template: this is a **linear analytics pipeline**, not an enricher. There's no "write back to a destination" and no two-source merge. The phases below reflect that shape.

**Honest warning up front:** Phases 1–4 and 6 are comfortable engineering. **Phase 5 is the climb** — it's where the poker statistics live, and where defining things correctly is genuinely fiddly. That's expected. If Phase 5 feels slow, you haven't gone wrong; you've reached the part the whole project exists to teach.

---

## Poker Primer, Part 1 — Table Mechanics (Read Before Phase 1)

You need just enough of this to understand what you're parsing. You do **not** need to know how to play well.

### A hand of No-Limit Texas Hold'em, step by step

1. **The button.** One seat is the "dealer button" (BTN). It rotates one seat clockwise every hand. Position is defined relative to it. The button acts *last* after the flop, which is the best seat to be in.

2. **Blinds (forced bets).** Before any cards, the two players to the left of the button post forced bets: the **small blind (SB)** and **big blind (BB)**. This money is *involuntary* — the player had no choice. **Remember this; it matters enormously for the stats later.**

3. **Hole cards.** Each player is dealt 2 private cards.

4. **The four betting rounds ("streets"):**
   - **Preflop** — after hole cards, before any shared cards. *This is where almost all the stats you care about are measured.*
   - **Flop** — 3 shared ("community") cards are dealt face-up; another betting round.
   - **Turn** — a 4th community card; another betting round.
   - **River** — a 5th community card; the final betting round.
   - **Showdown** — if two or more players remain, cards are revealed and the best hand wins.

### The five actions a player can take

| Action | Meaning |
|--------|---------|
| **Fold** | Give up the hand, lose nothing more. |
| **Check** | Pass the action without betting. Only legal if there's no bet to match. |
| **Call** | Match the current bet to stay in. |
| **Bet** | Put money in when nobody has yet bet this street. |
| **Raise** | Increase an existing bet (a "re-raise" raises a raise). |

### Two bits of jargon you'll meet immediately

- **Open / open-raise:** the *first* player to voluntarily raise preflop is "opening."
- **Limp:** just calling the big-blind amount preflop instead of raising. (A limper has voluntarily put money in, but has not raised — keep that distinction in your pocket for Phase 5.)

That's enough to read the data. The statistics themselves get their own primer right before Phase 5.

---

## Phase 1 — Environment & First Hand
**Goal:** Tooling in place, and parse a single real hand by hand so you understand the data's shape before building anything.
**Estimated effort:** 1–2 sessions

### Tasks
- [X] Create the project skeleton:
  ```
  poker-analytics/
  ├── src/              # Core modules (parser, etc.)
  ├── data/
  │   ├── raw/          # Downloaded PHH sample files
  │   └── parquet/      # Output of Phase 2
  ├── notebooks/        # Exploration
  ├── models/           # dbt project lives here (Phase 4+)
  ├── main.py
  ├── config.py
  ├── requirements.txt
  └── .env
  ```
- [X] venv on Python 3.12.x; `pip install` requests, pandas, pyarrow, ipykernel
- [X] Add `.env`, `data/`, `__pycache__/`, dbt target dirs to `.gitignore`
- [X] Download a **small sample** from the PHH dataset — a handful of files, not the full 21M. (You scale up in Phase 7, not now.)
- [X] In a notebook, open **one hand** and read it with your eyes. Identify: the blinds, each player's seat and position, and the sequence of actions on each street.
- [X] By hand, parse that one hand into three Python dicts:
  - `hand` — id, stakes, board cards
  - `players` — one row per player: seat, position, starting stack, amount won/lost
  - `actions` — one row per action: street, player, action type, amount
- [X] First Git commit with the skeleton

### Exit Criteria
One real hand is fully structured into the three dicts, and you can point at each field in the raw file and say what it is. Skeleton committed.

### Learning note
This manual parse is deliberate. There's a library (`pokerkit`, from the same group that published the dataset) that parses PHH for you — but using it now would rob you of understanding the format. Parse by hand first; reach for the library later if you choose.

---

## Phase 2 — Parse to Parquet
**Goal:** Turn many hands into flat records and store them as Parquet, and understand *why* Parquet.
**Estimated effort:** 1–2 sessions

### Tasks
- [ ] Write `src/parser.py` that turns a raw hand into the three flat record types from Phase 1
- [X] Loop it over a few thousand hands
- [X] Write the output as three Parquet files/folders: `hands`, `players`, `actions`
- [X] As an experiment, also write the same data as CSV. Compare: file size on disk, and time to read back and count rows.
- [X] Record the comparison numbers in **Field Notes**

### Learning note — why Parquet (the concept this phase teaches)
A CSV stores data **row by row**: all of row 1's columns, then all of row 2's. Parquet stores it **column by column**: all the `position` values together, then all the `amount` values together. Two consequences:
1. **Compression** — a column holds one kind of value (all positions, all amounts), and similar values next to each other compress far better than mixed rows.
2. **Selective reads** — to sum the `amount` column, a columnar engine reads *only that column* off disk, not every byte of every row. On wide data this is a huge difference.

This is the concrete version of "loading millions of hands is hard… but only the wrong way." Row formats make you read everything; columnar formats let you read just what the query needs.

### Exit Criteria
A `data/parquet/` folder holding several thousand hands across the three record types. You can state, with your own measured numbers, why Parquet beats CSV here.

---

## Phase 3 — DuckDB Over the Parquet
**Goal:** Query the Parquet directly with DuckDB and feel the speed.
**Estimated effort:** 1 session

### Tasks
- [X] `pip install duckdb`
- [X] From Python (or the DuckDB CLI), run `SELECT count(*) FROM 'data/parquet/hands/*.parquet'` — note there was **no import step**
- [ ] Write a few aggregate queries: hands per player, hands per stake level, average pot size
- [ ] Time a query over the largest sample you have

### Learning note — what's different about DuckDB
A traditional database (Postgres, the kind trackers use) needs you to *load* data into it first, into its own storage format, with indexes. DuckDB can point straight at Parquet files on disk and query them in place — no loading, no server, no indexes to maintain. It's an **OLAP** engine (analytical: scan-and-aggregate) rather than **OLTP** (transactional: many small inserts and point lookups, which is what trackers' Postgres is tuned for, and why they struggle at analysis-scale).

### Exit Criteria
Aggregate queries return correct results, fast, directly against the Parquet with no import step.

---

## Phase 4 — dbt Staging Layer
**Goal:** Stand up dbt-duckdb and build clean, typed staging models. Learn the mechanics on simple models before the hard ones.
**Estimated effort:** 1–2 sessions

### Tasks
- [X] `pip install dbt-duckdb`; `dbt init` inside the project
- [ ] Configure `profiles.yml` to point dbt at a DuckDB database file
- [ ] Define **sources** pointing at your raw Parquet tables (hands, players, actions)
- [ ] Build `slv_hands`, `slv_players`, `slv_actions` — light cleaning, consistent column names, correct data types
- [ ] Run `dbt build` and confirm green

### Learning note — the four dbt ideas you're meeting here
- **Source** — a declared pointer to raw data dbt didn't create (your Parquet).
- **Model** — a `SELECT` statement in a `.sql` file. dbt wraps it into a table or view for you.
- **ref / source functions** — how models reference each other (`{{ ref('stg_hands') }}`), so dbt works out the build order automatically.
- **Materialization** — whether a model becomes a `view` (recomputed on read) or a `table` (built once). Staging is usually views; marts usually tables.

This maps onto something you already know: your fact/dimension/grain instincts from ERP/CRM work transfer directly to dbt's layered structure. Staging = lightly-cleaned raw; marts (Phase 5) = the business-meaningful tables.

### Exit Criteria
`dbt build` runs your staging models green, and you can explain source vs ref vs materialization in your own words.

---

## Poker Primer, Part 2 — The Statistics (Read Before Phase 5)

This is the part you flagged as unknown territory, so it's the most detailed section in the document. Take it slowly; there's no rush.

Every stat below is a fraction: **how often a player did something ÷ how often they could have**. The whole skill is getting that denominator right. We build up from an easy denominator to a hard one.

### The mental model: numerator over denominator

A pro doesn't care that a player 3-bet 40 times. They care that a player 3-bet *40 times out of the 200 times they had the chance* — that's a rate, and rates are comparable between a player who's seen 500 hands and one who's seen 50,000. Your job in Phase 5 is to compute these rates correctly.

### Stat 1 — VPIP (Voluntarily Put money In Pot) — the easy denominator

**What it measures:** how often a player *chooses* to play a hand. The single most basic read on whether someone is "tight" (plays few hands) or "loose" (plays many).

- **Numerator:** hands where the player voluntarily put money in preflop — i.e. they **called or raised** before the flop.
- **Denominator:** every hand they were dealt.

**The one trap:** posting a blind does **not** count. That money was forced, not voluntary (this is why Part 1 told you to remember the blinds). If the big blind just checks their option because nobody raised, that also doesn't count — they put in no *extra* voluntary money. A limp **does** count (they chose to call).

> Worked example: A player is dealt 10 hands. They post the big blind in 2 of them and check (no raise came) — those don't count. In 3 hands they called or raised preflop. VPIP = 3/10 = **30%**.

### Stat 2 — PFR (PreFlop Raise) — also the easy denominator

**What it measures:** preflop *aggression*. How often a player takes the initiative by raising rather than just calling.

- **Numerator:** hands where the player **raised (or re-raised)** preflop.
- **Denominator:** every hand they were dealt.

**Relationship to VPIP:** PFR is always ≤ VPIP, because every raise is also "voluntarily putting money in," but not every voluntary call is a raise. The *gap* between them is itself a read: a small gap means an aggressive player (they raise most hands they play); a large gap means a passive player (they call/limp a lot). You don't need to compute the gap as its own stat, but knowing what it means helps you sanity-check your numbers.

> Worked example: same 10 hands. Of the 3 hands they voluntarily played, they raised in 2 and just called in 1. PFR = 2/10 = **20%**. (And VPIP 30% ≥ PFR 20%, as it must be — a good sanity check.)

### Stat 3 — 3-bet % — the hard, conditional denominator (this is the wrinkle)

First, the naming, because it's counter-intuitive:
- The **big blind** is treated as the "1st bet" (it's forced).
- The **first voluntary raise** preflop is the **2-bet** (the "open").
- A **re-raise of that open** is the **3-bet**. ← this is the one we're measuring
- A re-raise of the 3-bet is a 4-bet, and so on.

So a "3-bet" preflop simply means: **the first re-raise** — someone opened, and you came over the top of them.

**What it measures:** a sharper form of aggression — willingness to re-raise rather than just call or fold when someone has already raised.

Now the hard part — the denominator is **conditional**:

- **Numerator:** number of times the player 3-bet preflop (re-raised an open).
- **Denominator:** number of times the player **had the opportunity** to 3-bet — meaning the action reached them, exactly one raise (an open) was already standing, and no one had 3-bet yet. Only then did they *get* to choose between fold / call / 3-bet.

You **cannot** use "total hands dealt" as the denominator here. Most hands, nobody opens in front of the player, or the player has already folded before the raise — in those hands they never had the *option* to 3-bet, so those hands must not be in the denominator. Including them would understate the stat badly.

> Worked example: Over 100 hands, on 18 occasions a player opened before our player and the action came round to them with the chance to re-raise. Our player re-raised on 5 of those 18. **3-bet % = 5/18 = 28%** — *not* 5/100. The 82 hands where they never faced an open simply don't enter the calculation.

**Why this is the meaty dbt work:** to know whether a player "faced an open with the option to act," you have to reconstruct the *sequence* of preflop actions for each hand and, for each player, find their decision point and ask "what was the betting state in front of them right then?" That's an intermediate modelling step — you build a per-player-per-hand table of *opportunities and outcomes* first, and only then aggregate it into rates. That two-step (flag opportunities → aggregate) is the core lesson of Phase 5.

### How to keep yourself honest

- **Hand-verify.** Pick 5 real hands, work out each stat with pen and paper, and check your pipeline agrees. If the machine and the paper disagree, the machine is usually wrong in an interesting way — log it in Field Notes.
- **Use the sanity rule** VPIP ≥ PFR on every player. If it's ever violated, there's a bug.
- **Build one stat at a time.** Get VPIP fully correct and verified before touching PFR; get PFR done before 3-bet. Don't try to compute all three at once.

---

## Phase 5 — dbt Stats Marts (The Climb)
**Goal:** Build the intermediate "opportunities" model and the final player-stats mart. This is the heart of the project.
**Estimated effort:** 2–4 sessions (genuinely — give it room)

### Tasks
- [ ] Build VPIP first, end to end, and hand-verify against 5 real hands before moving on
- [ ] Build PFR; check the VPIP ≥ PFR rule holds for every player
- [ ] Build an **intermediate** model — e.g. `int_preflop_opportunities` — that produces, per player per hand: did they face an open with the option to act? did they 3-bet? (This is the conditional-denominator groundwork.)
- [ ] Build `mart_player_stats` that aggregates the above into VPIP, PFR, and 3-bet % per player
- [ ] Hand-verify 3-bet % against real hands — this is the one most likely to be subtly wrong
- [ ] Materialize the mart as a `table`

### Exit Criteria
A `mart_player_stats` table with VPIP, PFR and 3-bet % per player, each hand-verified against a handful of real hands, and VPIP ≥ PFR holding for everyone.

### Learning note
The pattern you're practising here — a thin **intermediate** layer that establishes *facts about each event* (faced an open? did they re-raise?), feeding a **mart** that aggregates those facts into rates — is the bread and butter of analytics engineering. Taxi data never makes you build it; poker forces it. That's why this dataset is the better teacher.

---

## Phase 6 — Streamlit Dashboard
**Goal:** A simple UI to pick a player and see their stats. Deliberately easy — a breather after Phase 5.
**Estimated effort:** 1 session

### Tasks
- [ ] Streamlit page that connects to the DuckDB file
- [ ] A selector for player; show their VPIP, PFR, 3-bet %, and hand count
- [ ] Keep business logic out of `app.py` — read from the mart, render. (Your usual region-folding / render-function habits apply.)

### Exit Criteria
Select a player, see their correct stats pulled live from the mart.

---

## Phase 7 — Scale & Stretch
**Goal:** Run the real volume, and only then try Victor's own data.
**Estimated effort:** 1–2 sessions per item

### Candidates
- [ ] Run the **full ~21.6M-hand PHH dataset** through the pipeline. Record timings — this is where the columnar stack proves the original "loading millions of hands" complaint was a tooling problem, not a data problem.
- [ ] Add a second parser for **Victor's exported histories** (modern PokerStars / HM3 format — different and messier than PHH). Treat it as a separate source feeding the same staging models.
- [ ] Additional stats once the three core ones are solid and verified: fold-to-3-bet, continuation-bet %, went-to-showdown %. (Each has its own conditional denominator — same pattern as 3-bet.)

### Notes
Add stretch items one at a time and verify each in isolation. Be honest about which are worth automating versus leaving alone — a spare-time project's scarce resource is your time, not compute.

---

## Field Notes
*Running engineer's log — discoveries, data quirks, decisions. Honest and practical.*

- [Pre-fill] Primary dataset = PHH (Zenodo, uoft computer poker group), ~21.6M NLHE hands, CC-BY 4.0 — credit required if published.
- [Pre-fill] IRC database rejected: no per-street bet amounts → can't compute betting stats. Kaggle "1M hands" rejected: hand-rank classification, no betting.
- [Pre-fill] `pokerkit` library can parse PHH, but Phase 1 parses by hand on purpose to learn the format.
- [Pre-fill] Sanity rule to assert everywhere: VPIP ≥ PFR for every player.
- [Pre-fill] The 3-bet denominator is conditional ("faced an open with the option to act"), NOT total hands. Most likely source of subtle bugs.
- [Date] — …

---

## Dependencies Reference

| Library | Purpose | Install |
|---------|---------|---------|
| `requests` | Download dataset files | `pip install requests` |
| `python-dotenv` | Load `.env` config | `pip install python-dotenv` |
| `ipykernel` | Jupyter kernel support | `pip install ipykernel` |
| `pandas` | In-notebook data handling | `pip install pandas` |
| `pyarrow` | Parquet read/write | `pip install pyarrow` |
| `duckdb` | Columnar query engine | `pip install duckdb` |
| `dbt-duckdb` | dbt adapter for DuckDB | `pip install dbt-duckdb` |
| `streamlit` | Dashboard UI | `pip install streamlit` |
| `pokerkit` | (Optional, later) PHH parser | `pip install pokerkit` |

---

## Principles To Keep In Mind

**Build one stat at a time, verify against paper.** VPIP fully done before PFR; PFR before 3-bet. Hand-check each against real hands. The machine disagreeing with your paper maths is a lesson, not a failure.

**Each phase leaves the project working.** Never end a session mid-refactor. Commit what works; leave a note.

**Cache the sample, scale last.** Work on a few thousand hands until Phase 7. Don't wait on 21M-row runs while iterating on logic.

**Prefer understanding over a fast fix.** Especially in Phase 5 — if a stat is wrong, work out *why* before patching. That's the whole point of the dataset.

**Write Field Notes as you go.** You won't remember why you made a decision three sessions from now.