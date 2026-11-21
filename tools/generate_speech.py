#!/usr/bin/env python3
"""Cache the game's Malayalam dialogue as MP3s. Needs: pip install gTTS.

Generation uses Google Translate speech through gTTS. The game itself plays
bundled files offline. Content hashes let edits regenerate only changed lines.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json
from pathlib import Path
import time

from gtts import gTTS

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets/audio/speech"
MANIFEST = ROOT / "data/speech_manifest.json"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workers", type=int, default=3)
    args = parser.parse_args()
    script = json.loads((ROOT / "data/speech.json").read_text())
    previous = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    entries = {}
    DEST.mkdir(parents=True, exist_ok=True)

    def generate(item):
        key, line = item
        digest = hashlib.sha256(line["ml"].encode()).hexdigest()
        path = DEST / (key + ".mp3")
        cached = previous.get("clips", {}).get(key, {})
        if path.exists() and cached.get("text_sha256") == digest:
            return key, cached
        temporary = path.with_suffix(".part")
        for attempt in range(4):
            try:
                gTTS(line["ml"], lang="ml", timeout=(10, 25)).save(temporary)
                if temporary.stat().st_size < 1000:
                    raise RuntimeError(f"Empty audio for {key}")
                temporary.replace(path)
                return key, {
                    "text_sha256": digest,
                    "audio_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "file": path.relative_to(ROOT).as_posix(),
                    "bytes": path.stat().st_size,
                }
            except Exception:
                temporary.unlink(missing_ok=True)
                if attempt == 3:
                    raise
                time.sleep(2 ** attempt)

    with ThreadPoolExecutor(max_workers=max(1, min(args.workers, 4))) as executor:
        pending = [executor.submit(generate, item) for item in script["lines"].items()]
        errors = []
        for task in as_completed(pending):
            try:
                key, entry = task.result()
                entries[key] = entry
                print(f"{len(entries)}/{len(pending)} {key}", flush=True)
            except Exception as error:
                errors.append(str(error))
        # Preserve successful work when a service request fails partway through.
        MANIFEST.write_text(json.dumps({
            "language": "ml", "provider": "Google Translate speech via gTTS",
            "clips": dict(sorted(entries.items())),
        }, indent=2) + "\n")
        if errors:
            raise SystemExit("Speech generation failed: " + "; ".join(errors))
    print(f"READY: {len(entries)} offline Malayalam clips", flush=True)


if __name__ == "__main__":
    main()
