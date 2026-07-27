# SMB3 world map (F4) — planned, not in this pass

## Goal

After clearing a level, return to an overworld map (SMB3-style) instead of the next `levelscreen`.

## Data (from dump)

- Source: `smb3/dump/worlds/world_N.json` (16×9 tiles + `level_pointers`)
- Emit: `mappacks/smb3/worldmap/world_N.txt`

## Proposed format

```
width¸height¸<RLE tiles>
nodes¸x¨y¨level¨clearable
paths¸from¨to¨dir
```

## Gamestate sketch

1. `gamestate = "worldmap"`
2. Node graph; lerp movement on udlr
3. Jump → `startlevel(N-M)`
4. Progress: `cleared[world][level] = true` unlocks adjacent nodes
5. After level clear → worldmap (not next levelscreen)

## Status

Stub only. Implement after mapsdk level pipeline is stable in-game.
