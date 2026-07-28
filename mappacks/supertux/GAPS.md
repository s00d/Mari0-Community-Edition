# SuperTux → Mari0 gaps (honest)

Imported: solid+decorative tile layers (composited), CC-BY-SA levels,
badguys→CE enemy JSON names, trampolines→spring, platforms, coin tiles,
weak_block→ice brick, flags via sequencetrigger X snapped to ground,
spawn snapped to floor. Collision from tiles.strf (not “any solid-layer tile”).
Entity markers use CE numeric ids (spawn=8, flag=11, spring=94, …).

Still missing / stubbed:
- Scripting (.nut), scripttrigger, init-script, sequencetrigger cutscenes
- Pushable rocks, fallblocks, unstable/magicblock, climbable, infoblock text
- Wind, bumper, doors as warps; tutorial decals/billboards
- Worldmap UI / hub progression (flat W-N level list instead)
- True badguy AI (snowball etc. use Mari0 goomba/koopa/… behaviour)
- Tux physics (ice friction), music, parallax backgrounds
