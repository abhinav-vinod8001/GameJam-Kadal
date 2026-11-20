# Verification · 21 November 2026

Latest build, **21 November 2026**: **93 checks passed** after the wildlife and hill temple update. Earlier sections below preserve the results from previous builds; see the final section for current validation.

Test environment: installed **Godot 4.3 stable**, Compatibility rendering, OpenGL 4.1 / Metal on **Apple M3**, native macOS window at **1280 × 800**.

| Check | Final result |
|---|---|
| Headless project import / resource parsing | Completed; no script or import errors |
| Rendered gameplay smoke suite | **39 passed, 0 failed**; clean final log |
| Rendered physics / held-input integration suite | **18 passed, 0 failed**; clean final log |
| Visual tour | Completed; rendered menu, prologue, village, Malayalam dialogue, shop, map, weapon trail, spear, monsoon, settings and highland views |
| Visual inspection | Menu, HUD, prologue, dialogue glyph shaping, shop prices, settings, field map, combat trail and highland / rain composition inspected |
| Launcher | Clean ZIP extraction imported its fonts / audio / script classes automatically, then passed all 39 smoke checks |

**Total: 57 automated checks passed.** Logs are preserved in `docs/validation/`. Function-level checks exercise the NPC → clue → enemies → ledger → return interaction chain and the early-camp-clear regression. Physics checks run actual fixed physics updates with held movement inputs, including walking over both bridge ramps without jumping, swimming buoyancy, boat propulsion and the lookout climb.

The visual tour's warmed readings were **92–121 FPS** across the sampled views at 1280 × 800. Startup / initial shader compilation readings were lower. These are short sample readings, not a long-duration performance benchmark or a guarantee for every machine.

The native rendered tests are the authoritative clean runtime checks. Godot 4.3's headless dummy renderer emits the known mesh cleanup diagnostic described in [Godot issue #86806](https://github.com/godotengine/godot/issues/86806), so gameplay tests are also run with the actual renderer. No engine upgrade is required to play this project.

The entire adventure has automated interaction-state coverage and navigation-component coverage. It has not had a separate human end-to-end playtest, professional animation review, native Malayalam editorial sign-off, or release QA across multiple platforms. See the README for production limits.


## Visual update · 21 November 2026

The scene was reimported and tested in Godot 4.3 Compatibility at 1280 × 800 with the renderer active on the Apple M3. The 39 smoke checks and 18 physics integration checks passed. The bridge check held forward for 660 fixed physics frames and confirmed that the player reached the far bank on foot.

The 60 FPS capped visual tour included sunny village gameplay, the monsoon forest, the highland, and a close-up of Arun's new model. Sampled gameplay views ranged from 42 to 60 FPS after startup. These are point readings from a scripted tour. The updated models use more geometry than the original assets, and the rigid character meshes are batched per animation joint to reduce draw calls.

See `docs/validation/visual-update-*.txt` for the new logs.

## Reference-sheet upgrade · 21 November 2026

The final reference pass was imported and rendered in Godot 4.3 Compatibility on the Apple M3 at 1280 × 800. All **39 smoke checks and 18 physics integration checks passed** after the final character detail adjustment. The visual tour completed all 19 captures, covering the existing interface and gameplay views plus dedicated Arun, Kuntham, cottage, market, and ruins close-ups.

After allowing three seconds for rendering to settle independently of PNG writes, the three gameplay samples each reached the configured 60 FPS cap:

| Sample | FPS (capped) | Draw calls |
|---|---:|---:|
| Village | 60 | 942 |
| Backwater | 60 | 689 |
| Forest in heavy monsoon | 60 | 553 |

These are short point samples, not a sustained benchmark. The screenshot capture loop reports lower readings in some views because it includes synchronous PNG readback / writes; those readings are preserved in the full log. Mesh sharing, static MultiMeshes, per-joint character merging, and a limited number of lamp lights remain active.

All 11 files in `docs/validation/reference-protected-files.json` match their pre-upgrade SHA-256 checksums. Avatar `animate()` and NPC `_process()` also match the pre-upgrade distribution. The runtime change list in `reference-visual-scope.json` contains only visual builders, shaders, and environment lighting. Fresh logs are saved as `docs/validation/reference-{import,smoke,integration,tour}.txt`.

A newly extracted package also imported successfully without script, shader, or resource errors. The final ZIP was checked for CRC integrity and byte-for-byte agreement with the source files; the unpacked `dist/KADAL` copy was refreshed from the same archive. See `docs/validation/reference-package-import.txt` for the clean import log.

## Water, movement, and vanchi · 21 November 2026

The water and movement build passed **39 smoke checks and 36 physics integration checks, 75 total**, in Godot 4.3 Compatibility on the Apple M3 at 1280 × 800. Import, both gameplay suites, the full visual tour, and the dedicated water / movement tour completed without script, shader, resource, or cleanup errors. Logs are stored in `docs/validation/water-motion-*.txt`.

The new integration coverage exercises controlled stopping, analog speed, retained jump momentum, articulated joints, swimming and climbing poses, a seated rider following the boat, steering, coasting, reverse paddling, and weapon restoration on disembark. Both paddle grips were checked across a full stroke; the largest measured hand-to-grip error was under 0.1 millimetres. The suite also verifies the reflection target's 768-pixel width and exclusion of the water layer to prevent recursive rendering. Existing bridge, swimming, boat, combat timing, quest, economy, and mode checks continue to pass.

The dedicated tour includes clear and monsoon water, an unoccupied vanchi, seated paddling, running, and swimming. Animated paddling and running previews were assembled from 24 actual rendered frames each. The warmed water-tour samples recorded **60 FPS in the village, 60 FPS at the waterfront, and 59 FPS aboard the boat**, with the game capped at 60 FPS. The full tour recorded 60 FPS in its village, backwater, and monsoon forest samples. These are short point samples; PNG capture and file writes cause substantially lower readings during the recording loops and are not a sustained gameplay benchmark.

The reflection uses a shared-world SubViewport at 768 × 480 for the default aspect ratio, refreshed at up to 30 Hz with FXAA. It clips submerged character, boat, and painted-surface fragments only for the mirrored camera. Actual underwater views retain their geometry and fall back to the water's sky reflection. The reflection target excludes the water, labels, and dense grass, while preserving the visible environment, banks, boats, and characters.

The eight files in `water-motion-protected-files.json` remain byte-for-byte unchanged: combat rules and effects, enemy behavior, HUD, map, quest state, and weapon / dialogue data. The earlier reference-pass manifest documents that earlier build; this update intentionally changes player, avatar, and boat movement code.

A fresh ZIP extraction imported cleanly with the new global script classes and shaders. Final packaging validates CRC integrity, an executable launcher, and byte-for-byte agreement between the archive, source project, and refreshed `dist/KADAL` folder.

## Forest, paddy, market, and village population · 21 November 2026

The populated build passed **44 smoke checks and 38 physics integration checks, 82 total**, in Godot 4.3 Compatibility on the Apple M3 at 1280 × 800. Import, gameplay checks, and the new population tour completed without script, shader, or cleanup errors. Logs are in `docs/validation/population-*.txt`.

The world now contains **468 additional trees**, **3,024 planted rice clumps**, **13 market stalls** (eight new), and **30 friendly NPCs** (24 new). The forest adds clustered crowns, ferns, rocks, and fallen logs. Paddy fields add wet planting beds, irrigation, bunds, sluice gates, farm supplies, a field shelter, handcarts, and a scarecrow. Rice plots remain open, with palms relocated to their edges. Market additions include varied stock, a packed-earth square, bunting, pottery, carts, and vendors.

New checks cover the content population, ambient conversations, story isolation, villagers walking their routes, and routes stopping when a modal is open. The existing player movement, bridge, swimming, boat, climb, combat timing, economy, and complete quest checks continue to pass. Trees keep margins around paths, buildings, and interactable landmarks; ambient villagers have no blocking colliders.

After the crowd rendering adjustment, the warmed population-tour samples reached the 60 FPS cap in the **market, paddy fields, and forest**. These are three-second settling / point samples, not a sustained benchmark. Screenshot-loop readings are lower because they include PNG readback and file writes. The new trees use shared mesh templates and spatial MultiMeshes. Rice and ferns are instanced, and ambient animation updates reduce with viewing distance. Additional villagers use simple contact shadows; waterfront fishers retain their reflections, while the other new residents are excluded from the mirrored water view. Hero and original story-character rendering remains unchanged.

The 13 files in `population-protected-files.json` match their pre-update checksums: player and avatar movement, combat and effects, enemy behavior, boat controls, HUD, map, quest management, main interactions, weapon data, and the six original bilingual dialogues. Additional conversations and routes live in the separate `data/villagers.json` file.

A fresh extracted package imported successfully with the new population builder, villagers, data, and shaders. Archive CRC integrity, the executable launcher, and source / distribution parity were verified for the final ZIP.


## Wildlife and hill temple · 21 November 2026

This build passed **49 smoke checks and 44 physics integration checks, 93 total**, using Godot 4.3 Compatibility on the Apple M3 at 1280 × 800. New coverage checks all four species and their population counts, elephants walking with articulated trunks, nearby dogs pausing to watch the player, deer moving away from an approach, wildlife pausing during modal screens, walking up through the temple gateway without jumping, healing at the temple, and the one-time discovery reward. Existing village, player movement, bridge, combat timing, quest, economy, swimming, boat, and lookout checks continue to pass.

Four cats and three dogs live near the village; five spotted deer inhabit two woodland clearings; two elephants roam western forest clearings. Animals use terrain collision and bounded target selection, with grazing / idle pauses, curiosity, deer flight, joint animation, contact shadows, visibility ranges, and reduced distant animation updates. They do not block the player or become combat targets. Open woodland habitats are reserved before trees are planted; the additional tree total remains 468.

The hill shrine is rebuilt as a two-tier tiled timber temple with a stone retaining platform, level courtyard, carved veranda columns, brass trim and finials, shutters, gateway, hanging bell, lamps, and flower offerings. Smooth collision under the visual stair approach connects the hill trail to the courtyard and veranda. The rest point preserves the original heal, stamina, and discovery behavior.

All 13 entries in `wildlife-protected-files.json` match their pre-update SHA-256 checksums, including player / avatar movement, combat, enemy behavior, HUD, map, quests, main interactions, boat controls, and original weapon / dialogue data. Source import and rendered suite logs are in `docs/validation/wildlife-*.txt`. The dedicated visual tour covers all four animals, the temple exterior, courtyard, approach, and monsoon weather.

After three seconds of settling in each view, capped gameplay point samples were **59 FPS in the village** and **60 FPS at the deer clearing, elephant clearing, and hill temple**. These are short readings rather than a sustained benchmark. Screenshot-loop rates are lower because they include PNG readback and disk writes.

A fresh ZIP extraction imported all new global script classes and resources cleanly, then passed the complete **49-check smoke suite** using the real renderer. The final archive was checked for CRC integrity, executable launcher permissions, byte-for-byte source agreement, and parity with the refreshed `dist/KADAL` folder.
