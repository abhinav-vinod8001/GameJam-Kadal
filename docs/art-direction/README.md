# KADAL visual targets

These user-supplied concept sheets guide the in-game 3D work. The images are stored by subject, since attachment display order differs from the numbered brief.

| Category | Concept sheet | In-game target |
|---|---|---|
| Character and weapons | [Arun, raiders, Val, Paricha and Kuntham](references/01-arun-raiders-weapons.jpg) | Slender proportions, tied headbands, blue sash, ivory kasavu mundu, curved steel and domed brass shield |
| Village | [Cottage, market, dock and boat](references/02-cottage-market-jetty.jpg) | Raised laterite plinths, terracotta profiles, turned timber, dyed canopies and stocked stalls |
| Ruins, lamps and plants | [Ruins, vilakku, coconut palms and banyan](references/03-ruins-vilakku-foliage.jpg) | Layered stone moldings, vines, warm flame, curved palms and dense crowns |
| Lighting | [Azhimukham approach](references/04-village-lighting.jpg) | Warm sun, cool mountain haze, stepped lighting, and a soft transition from trail to grass |

The supplemental [vendors and boatman](references/05-vendors-boatman.jpg), [gurukkal, smith and elder](references/06-gurukkal-smith-elder.jpg), and [trade props](references/07-trades-and-props.jpg) are visual references. The two identical gurukkal sheets share one project copy. The attachments are 2D concept art. The in-game models are built in Godot, and the reference images are excluded from runtime import.

## Implemented reference pass · 21 November 2026

The four categories were applied in sequence. Character builders now include tapered limbs, layered cloth, a visible tied headband, the blue sash, and rebuilt weapon silhouettes. NPCs use role-specific clothing, hair, and accessories. Architecture includes raised bases, carved verandahs, shutter details, brass lamps, draped market cloth, baskets, spices, and pots. Ruins include stepped bases and capitals, moss variation, and trailing vines; roadside vilakku use emissive flames with a limited number of real lights. Palms have curved trunks, layered fronds, and coconuts; broadleaf trees combine wind-driven leaves and clustered crowns.

The final lighting pass adds stepped character / foliage shading, rim light, golden sunlight, softer shadow contrast, teal atmospheric depth, and mottled transparent trail edges. Shared meshes, static MultiMeshes, and per-joint character mesh merging keep rendering costs under control.

Rendered examples: [Arun](../previews/arun.png), [Kuntham](../previews/kuntham.png), [cottage](../previews/cottage.png), [market](../previews/market.png), and [ruins](../previews/ruins.png). These show the playable procedural assets. They remain stylized approximations of the concept sheets.

The [protected-file manifest](../validation/reference-protected-files.json) records unchanged movement, combat, effects, enemy logic, quest state, HUD, map, boat, dialogue data, and weapon data. Avatar animation and NPC update methods also match the pre-upgrade distribution. Visual builders, materials, shaders, and environment lighting carry the runtime changes.

## Subsequent water and movement pass

The next user request explicitly expanded the work to water quality, reflections, character movement, boat styling, and animation. That pass adds mirrored scenery, depth-sensitive shallows, articulated limbs, movement-state poses, a rebuilt vanchi, and seated paddling. Player, avatar, and boat scripts therefore now differ from the earlier reference-only manifest. Combat rules, quest state, HUD, map, and game data are still unchanged; the current scope is recorded in [water-motion-protected-files.json](../validation/water-motion-protected-files.json).

[Reflective water](../previews/water.png) · [Vanchi](../previews/boat.png) · [Paddling](../previews/paddling.gif) · [Running](../previews/running.gif)
