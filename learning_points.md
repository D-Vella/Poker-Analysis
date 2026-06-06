# Learning Points

A running log of issues encountered and lessons learned during this project.

---

## 1. Pandas DataFrame from a list of nested dicts creates a wide, sparse table

**Symptom:** `pd.DataFrame(my_list)` hangs for minutes or never completes, even though the list itself was built quickly.

**Root cause:** When the list items are dicts whose *keys are entity names* (e.g. player names) and whose *values are nested dicts*, Pandas treats each unique key as a column. With hundreds of thousands of rows and many unique keys, this produces an enormous sparse DataFrame — one column per unique player name — which is both slow to build and wasteful in memory.

**Example (bad):**
```python
# players is a list of dicts like:
# [{'Alice': {'seat': 1, 'stack': 100}, 'Bob': {'seat': 2, 'stack': 200}}, ...]
players_df = pd.DataFrame(players)  # creates one column per player name!
```

**Fix — flatten to proper rows first:**
```python
players_flat = [
    {'hand_id': hands[i]['id'], 'player_name': name, **stats}
    for i, player_dict in enumerate(players)
    for name, stats in player_dict.items()
]
players_df = pd.DataFrame(players_flat)
```

**Lesson:** Data passed to `pd.DataFrame()` should be a list of flat dicts where keys are *column names*, not entity identifiers. If your dict keys represent entities (players, products, users), flatten them into a `name`/`id` column first. The resulting table will have more rows but far fewer columns — which is the correct normalised structure.

---
