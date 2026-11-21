# Asset provenance

| Asset | Source | Licence / note |
|---|---|---|
| Procedural world, characters, weapons, net structures, buildings, plants, boats, wildlife and hill temple | Original code in `scripts/world/`, `scripts/player/`, `scripts/vehicles/`, `scripts/wildlife/`, `scripts/enemies/` | Project MIT licence; original generated geometry |
| Sky, water, grass, foliage, rice, paddy water, market earth, contact shadows, painted surfaces, market cloth, waterfall and interface shaders | Original project shader source in `shaders/` | Project MIT licence |
| 20 WAV effects / ambience files | Original procedural synthesis; `tools/generate_audio.py` | Project MIT licence; no sampled commercial recordings or voice clones |
| 114 Malayalam speech MP3s in `audio/speech/` | Original game dialogue in `data/speech.json`, synthesized with Google Translate speech through [gTTS](https://github.com/pndurette/gTTS); `tools/generate_speech.py` | Synthesized speech, not a human recording or voice clone. gTTS is MIT-licensed; that software licence does not grant a separate licence to the speech service or its output. Text / audio hashes are recorded in `data/speech_manifest.json`. |
| Application icon | Original `assets/icon.svg` | Project MIT licence |
| Cormorant Garamond variable font | [Google Fonts / Cormorant Garamond](https://github.com/google/fonts/tree/main/ofl/cormorantgaramond) | SIL Open Font License; `fonts/cormorantgaramond-OFL.txt` |
| Noto Sans Malayalam variable font | [Google Fonts / Noto Sans Malayalam](https://github.com/google/fonts/tree/main/ofl/notosansmalayalam), [Noto Malayalam project](https://notofonts.github.io/malayalam/) | SIL Open Font License; `fonts/notosansmalayalam-OFL.txt` |
| Godot runtime and its default UI font | Installed Godot distribution | Distributed by Godot under its own notices; see [Godot licence](https://godotengine.org/license/) |
| Visual target sheets in `docs/art-direction/references/` | User-supplied concept images, including supplemental NPC / prop sheets | Reference material supplied by the user; no third-party licence grant is asserted. Excluded from Godot runtime import with `.gdignore`; these are not in-game textures or meshes. |

There are no third-party character models, purchased art packs, copied maps or soundtrack recordings in this demo. All game content, including speech playback, is available offline after checkout / download. The Malayalam conversations are prewritten Unicode text with matching bundled speech and English translations. Only regenerating speech requires a network connection and the optional gTTS development dependency.
