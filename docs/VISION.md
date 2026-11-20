# A stronger direction for KADAL

## The promise

**Read the coast. Master the blade. Bring the missing home.**

KADAL works best as a small place the player comes to know: a bell above the hills, a red sail caught in the reeds, warm lamps on the road home. A complete, carefully paced journey gives this setting more weight than a vast map filled with repeatable icons.

Arun's strength is human. A successful defence is footwork and timing. The extraordinary belongs to the land: an unexplained bell, an old drawing, a date that should be impossible. Avoid elemental attacks, floating technological interfaces in the fiction, and powers that remove the value of boats or trails.

## Three pillars

1. **A coast with a memory.** A connected village, river, forest, highland and old courtyard. Buildings, food, language, fishing structures and the shape of the water carry the identity. Malayalam appears in conversation, alongside useful English translations.
2. **Readable human combat.** Anticipation → active strike → recovery. Distinct weapon reach and commitment. Clear enemy warnings. A timed parry opens a real counter window. Effects explain contact and motion; they do not disguise damage that happens instantly on a button press.
3. **A reason to return.** The road outward teaches landmarks. The road home makes them familiar. Villagers give context, the merchant provides useful supplies, and the shrine offers a quiet discovery beyond the main quest.

## The prologue's rhythm

- **Belonging:** arrive at the banyan and jetty; Ravi gives a personal reason to investigate.
- **Listening:** the spice market connects the missing cargo with Meera's red-sail sighting.
- **Reading the landscape:** the torn sail points across the bridge and toward the forest's stone lamps.
- **Commitment:** two raiders and their guard force the player to use spacing, stamina and defence.
- **Return:** the ledger resolves the disappearance. Ravi brings the escapees home; the recovered drawing introduces the shrine mystery.
- **Breathing room:** stay in the same world to practise, boat, gather, visit the lookout or find the hill shrine.

The current demo implements this route, with the villagers' return described in the ending. A later production version should stage the rescue and return physically, using a short in-engine arrival scene.

## Weapons should change decisions

| Weapon | The decision | Motion and sound |
|---|---|---|
| Sword and shield | Commit to a combo or keep stamina for a parry? | Measured alternating cuts; clean edge crescent; warm steel ring |
| Spear | Maintain distance and line up a narrow thrust | Linear streak; short air displacement; precise point of contact |
| Staff | Create space when two opponents close in | Wide sweep; wood resonance; grounded dust |
| Dagger | Enter close range for fast recovery | Small sharp cuts; quick cloth / air sound; compact impacts |
| Urumi | Spend stamina on wide coverage, then survive recovery | Flexible moving ribbon; layered steel traces; long swish |

Every successful hit needs a visible contact point, a brief reaction, a distinct sound and a readable result. Misses should still show the weapon's motion and sound. Perfect parries deserve the strongest brief feedback: sparks, ring, hit pause, stagger and an opening for a counter. They should never become an elemental explosion.

## Effects language

- **Ivory / pale steel:** motion and cutting edges.
- **Warm gold:** metal contact, parry timing and discoveries.
- **Earth / muted ochre:** feet, rolling, blunt force and landings.
- **Pale turquoise:** displaced water, wakes and rain.
- **Natural leaf green:** gathering and healing.
- **Amber warning rings:** enemy attack preparation; disappear when the attack starts.

Keep trails brief enough to read the next attack. Make camera shake optional, bound effect lifetimes, and batch repeated scenery before adding expensive post-processing.

## Scope discipline

The existing playable slice has five weapon configurations, one full investigation, six conversational NPCs, one merchant and one boat. Make those excellent before adding another region. The practical next order is:

1. Replace the procedural hero with an original rigged character and five authored weapon animation sets.
2. Give the village and forest a consistent hand-authored environment kit, with better ground cover and water edges.
3. Add more opponent attack variations, navigation around obstacles, difficulty tuning and accessibility remapping.
4. Stage the boat rescue and homecoming; introduce checkpoint saves.
5. Commission native Malayalam writing review, performances if desired, and a culturally informed art / history review.

Do not expand into a huge branching RPG until this short journey is compelling in repeated playtests.
