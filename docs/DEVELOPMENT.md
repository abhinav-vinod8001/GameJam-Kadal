# Build stages

The workspace began empty. Godot 4.3 stable was available at `/opt/homebrew/bin/godot`; no plugins or external model packs were required. Compatibility rendering was selected and tested on the Apple M3. Malayalam and title fonts were bundled with their licences.

| Stage | Implemented result | Validation |
|---|---|---|
| Foundation | One project; animated world menu; shared Story / Free Roam; third-person controller and collision spring arm | Resource import, mode switching and camera smoke checks; held-input movement, jump and landing integration checks |
| World | Connected heightfield, river, bridge, five named areas, modular tiled homes, market, nets, kalari, ruins, shrine, lookout and waterfall | Rendered screenshots; island / forest collision and climb integration checks |
| Conversation | Six data-driven NPCs; Malayalam and English; response choices; herb / honing merchant | Font glyph assertion, rendered dialogue, shop and affordability checks |
| Spoken village life | 114 offline Malayalam clips for 30 friendly NPCs and 12 soldiers; proximity / occlusion checks, line rotation, weather / quest context, synchronized subtitles, voiced follow-ups and saved audio / translation preferences; distance-driven articulated NPC gait | Speech asset / text hash checks, approach and interruption tests, occlusion / cooldown tests, foot-ground measurements, rendered subtitle / conversation / settings views |
| Combat | Five weapon models / profiles; timed active hit windows; combo; heavy; guard; parry; counter; dodge; enemy patrol / chase / telegraph / recovery / stagger / defeat | Combat smoke checks; actual physics attack windup and active window; rendered weapon trails |
| Adventure | End-to-end investigation; markers; rewards; healing; chests; gathering; opening doors; boat | Quest order and early-camp regression; economy and healing checks; held-input boat test |
| Wildlife and hill temple | Four species with bounded wandering, grazing, curiosity, deer flight and articulated joints; tiered temple, courtyard and walkable hill approach | Species counts, collision / behavior checks, temple navigation and discovery reward checks; rendered portraits and temple views |
| Soldier squads | Twelve soldiers in level 1–3 squads; shared alerting, flanking, overlapping strikes, local obstacle probes and camp gateway routing; Easy / Normal / Hard; camp-specific ledger gate and clear rewards | Concurrent-attack and cap tests, strike / parry / dodge checks, natural camp pursuit, physical gateway traversal, warning visibility and quest regressions |
| Atmosphere | Weather transitions, rain, thunder, water / grass / waterfall shaders, original sounds, birds, bounded particles, optional camera shake, scenery batching | Rendered visual tour, native test logs and screenshot inspection |

## Technical boundaries

The world is generated from deterministic code when the main scene loads. Static primitives share resources and are grouped into MultiMeshes. Dynamic characters, doors and collectibles keep separate nodes. Grass is one wind-animated MultiMesh. The terrain is a static concave collision surface with backface collision enabled at banks. Runtime settings are stored in Godot's `user://settings.cfg`.

Gameplay is separated into controller, visual avatar, combat, effects, enemy, NPC, vehicle, weather, audio, interface and world scripts. The autoload holds the small demo's mode, quest and inventory state. Both game modes use the same instances and code paths.

The tests deliberately distinguish function-level checks from physical simulation and visual inspection. Passing a quest state check alone does not prove that a player can navigate there; the integration suite also checks movement, terrain support, water, climbing and boat input.

## Revisions found through testing

- Corrected a CPUParticles3D API mismatch in rain intensity handling.
- Corrected UI offsets for anchored HUD controls.
- Corrected terrain face orientation and enabled robust riverbank collision.
- Fixed a merchant string's percent formatting.
- Fixed the lookout climb's facing and exit direction.
- Prevented an early camp clear from blocking later story progression.
- Kept the death screen available until the player respawns or returns to the menu.
- Disabled unsupported MSAA on this device and selected FXAA.
- Adjusted lighting and water normals after inspecting actual rendered images.

Current production limits are listed honestly in the README. Procedural geometry and animation are replaceable foundations, not final AAA assets.
