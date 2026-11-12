# Project Last Wave — Game Art Bible

- Version: 1.0.0
- Baseline: Project Last Wave (`project-last-wave`)
- Context Reference: `docs/CONTEXT.md`, `docs/architecture/combat-build-design.md`, `docs/plans/plan-03-combat.md`
- Status Notation: Settled project decisions are cited directly; aesthetic expansions not yet confirmed by Project Owner (`Stang`) are marked explicitly as `PROPOSED` + `OWNER_DECISION_REQUIRED`.

---

## 1. Theme & Art Direction

### Verified Foundation
Project Last Wave is a fast-paced **Roblox Anime Action Endless-Wave Roguelike** designed for 1–4 players. Players battle endless waves of zombies and high-threat bosses utilizing iconic Anime Power Kits mapped to universal controls (LMB 3-hit melee combo, RMB ranged attack, Z/X/C unique skills, universal Q dash).

The core artistic identity is high-energy **Modern Shonen Anime Action**:
- Punchy, readable silhouettes visible through dense crowd combat.
- Heavy contrast cel-shaded aesthetics featuring dark ink strokes paired with hyper-saturated neon energy cores.
- The player character retains their **personal Roblox Avatar appearance** (custom hair, clothes, and accessories) fitted onto a strictly standardized R15 armature. Personal cosmetics never distort gameplay hitboxes or reach.
- Power identity is projected through **weapons, focus props, aura flourishes, and signature animation poses**, rather than full-body avatar mesh replacements.

### The 5 Verified Initial Representatives
As authorized in `docs/architecture/combat-build-design.md` §10 and `docs/plans/plan-03-combat.md` §1:
1. **Sword Class**: **Ichigo** (*Bleach* — Zangetsu energy wave blade; swift crescent ribbons and Getsuga slashes).
2. **Gun Class**: **Lady** (*Devil May Cry* — Heavy multi-segment launcher; cylindrical missile/bullet blasts and counter-shots).
3. **Gun + Sword Hybrid Class**: **Nero** (*Devil May Cry* — Red Queen motorized blade with rev throttle + Blue Rose sidearm).
4. **Fist Class**: **Luffy** (*One Piece* — Unarmed martial arts with dynamic rubber limb elongation, Gatling flurries, and giant fist slam).
5. **Special Power Class**: **Megumi** (*Jujutsu Kaisen* — Shadow summons: Divine Dog forward lunge, Toad tongue drag, Nue electric dive impact).

---

## 2. Color Palette & Lighting Hierarchy

### Core Shonen Anime Contrast
Every visual effect and combat asset adheres to a 3-tier contrast rule:
1. **Black Ink Rim / Outline**: Deep `#05070A` to `#10141E` outer stroke bounding energetic actions.
2. **Saturated Body Tint**: High-chroma color characterizing the specific anime power kit.
3. **Pure White / Core Glow**: `#FFFFFF` to `#F0FAFF` intense center delivering instant visual feedback on strike points.

### Kit-Specific Color Palettes (Verified)
- **Ichigo (Getsuga / Zangetsu)**:
  - *Core*: Pure White (`#FFFFFF`).
  - *Mid-Tone / Glow*: Vibrant Cyan-Blue (`#1FB6FF` to `#7FE9FF`).
  - *Edge Stroke*: Deep Inky Charcoal (`#05070A`).
  - *Impact Flash*: Starburst Cyan (`#D0F4FF`).
- **Lady (Firearm / Launcher)**:
  - *Core*: White-Yellow Blast Core (`#FFFCE0`).
  - *Mid-Tone / Glow*: Fiery Amber-Orange (`#FF7A00` to `#FF4500`).
  - *Edge Stroke*: Industrial Gunmetal Slate (`#1A1C23`).
  - *Smoke / Debris*: Desaturated Warm Charcoal (`#38332E`).
- **Nero (Exceed / Red Queen & Blue Rose)**:
  - *Neutral State*: Sleek Brushed Steel (`#949BA4`) and Mechanical Crimson Accents (`#B2182B`).
  - *Rev / Full Charge*: Glowing Molten Scarlet (`#FF1E27` to `#FF6B00`) with white heat embers.
  - *Ranged Discharge*: Electric Blue Powder Puff (`#00D2FF`).
- **Luffy (Rubber Combat & Haki Impact)**:
  - *Action Rings / Stretch Trails*: Translucent White/Silver ink ribbons (`#E8ECEF`).
  - *Impact Stars*: Warm Cream-Yellow (`#FFF8B0`) and Golden Spark Bursts (`#FFB800`).
  - *Impact Spikes*: Stark Manga Black Spikes (`#0A0A0C`).
  - *Shockwave / Cracks*: High-contrast Monochrome (`#FFFFFF` to `#202024`).
- **Megumi (Ten Shadows)**:
  - *Shadow Pool / Emergence*: Abyssal Ink Black (`#050508`) with liquid shadow ripples.
  - *Divine Dog*: Stark White fur contrast with blood-red eye flashes (`#E81B23`).
  - *Toad*: Earthy Swamp Olive (`#3B442B`) with pale flesh highlights.
  - *Nue*: Electric Gold Feathers (`#F5A623`) with pale blue shock sparks (`#90E0EF`).

### Environment & Mood Palette Expansions
> [!NOTE]
> `PROPOSED` + `OWNER_DECISION_REQUIRED`: The following environment mood progression across wave tiers is proposed for visual pacing:
> - *Waves 1–5 (Dusk Courtyard)*: Deep twilight navy skybox (`#0D1322`), warm amber lantern beacons (`#FF9E2C`).
> - *Waves 6–10 (Midnight Incursion)*: Cold moonlight slate (`#1C2333`), pale purple atmospheric fog (`#2B1B3D`).
> - *Boss Intermission / Blood Moon*: Deep crimson zenith (`#4A0E17`), high-contrast rim lighting.

---

## 3. Shape Language & Silhouette Clarity

### Silhouette Principles
In a horde-survival roguelike, visual clarity under dense mob clutter is paramount:
1. **Readable Silhouette Over Fine Texture**: Poses and weapon swings must be recognizable purely from their silhouette against high-contrast backgrounds.
2. **Dynamic Angles**: Attacks utilize sharp diagonals (45° slashes), clean crescent arcs (180° horizontal sweeps), and decisive vertical plunges (90° overhead finishers).
3. **Exaggerated Action Poses**: Key action frames utilize extended limb extensions and dramatic weapon arcs before snapping back to neutral.

### Shape Primitives by Class
- **Blades & Slashes**: Tapered ribbon curves, crescent moons, and parabolic wake geometries.
- **Firearms & Missiles**: Rigid cylinders, conical muzzle cones, and concentric expansion rings.
- **Unarmed & Stretching**: Cylindrical bone chains, circular expansion spheres (Elephant Gun), and radiating manga impact stars.
- **Shadow Summons**: Liquid organic splatters, sharp beast fangs, and avian wing silhouettes.

---

## 4. Character Proportions & R15 Rig Normalization

### Standardized Rig Invariant
Per `docs/CONTEXT.md` §1 & §7 and `docs/plans/plan-03-combat.md` §1:
- All player combat is evaluated on an **identical standard R15 reference rig** (`ServerStorage.LastWaveRigReference.StandardR15`).
- **Uniform Dimensions**: Every character shares identical bone segment lengths, joint pivot offsets, base height (~5.0 studs), and collision boundaries.
- **Cosmetic Independence**: Personal avatar packages, bundle scales, and player cosmetics **never alter gameplay reach, weapon grip positions, or hitboxes**.
- **Luffy Visual Exception**: Luffy's arm stretching and Elephant Gun inflation are implemented as **temporary client-side visual mesh/joint socket scaling** with immediate recovery to baseline. They do not permanently alter the server's authoritative character envelope.

---

## 5. Materials, Shading & Lighting Budgets

### Material Contrast
To maintain a crisp anime visual style in the Roblox engine:
- **SmoothPlastic & Glass**: Dominant material for weapon blades, character clothing, and stylized props. Low roughness delivers sharp specular highlights without noisy PBR grain.
- **Neon Material**: Reserved strictly for energy cutting edges, muzzle flash points, glowing runes, and core VFX emitters.
- **Metal Material**: Used sparingly on mechanical housings (Nero engine block, Lady launcher stock) to provide subtle industrial contrast.

### Lighting & PointLight Budgets
To prevent visual blowout and lag on lower-end mobile devices:
- **PointLight Ceilings**: Maximum of **2 active PointLights per player character** (1 for weapon aura/charge, 1 for momentary impact flash).
- **PointLight Lifetime**: Attack impact lights must have a duration $\le 0.15\text{s}$ with brightness $\le 3.0$ and range $\le 14\text{ studs}$.
- **Global Bloom**: Kept at subtle levels (Intensity $\le 0.4$, Threshold $\ge 0.85$) to prevent white-out when multiple players attack simultaneously.

---

## 6. Combat VFX Style & Layering Architecture

### The 3-Layer Anime VFX Standard
All combat visual effects in Project Last Wave are structured into three distinct layers:
```
Layer 1: Dark Ink Stroke Outer Shell (Contrast / Boundary Definition)
Layer 2: Saturated Chromatic Ribbon (Anime Identity & Hue Projection)
Layer 3: Pure White High-Intensity Core (Punch / Impact Point)
```

### Visual Effect Guidelines
1. **Slash Ribbons**: Constructed using shared-joint cubic Bézier ribbons or dual-emitter trails. Clean fadeout along the tail with zero lingering edge artifacts.
2. **Impact Frames**: High-priority hits (LMB finisher, heavy skill strikes) trigger a **1-to-2 frame pure white micro-flash** on the target dummy/enemy.
3. **Manga Ground Cracks**: Planar decal or billboard shockwaves projected onto floor geometry, fading cleanly within $1.2\text{s}$ without terrain destruction.
4. **Authoritative Separation**: **VFX NEVER decides damage**. All visual effects are triggered by server cues (`Begin`, `Event`, `Impact`, `Release`) or local prediction buffers, and immediately cleaned up on cancellation or death.

---

## 7. Animation Style & Frame Cadence

### The Shonen Combat Rhythm
Animations prioritize snappy, responsive feel over hyper-realistic physics:
$$\text{Startup (Anticipation)} \longrightarrow \text{Active (Hit Frame)} \longrightarrow \text{Recovery (Follow-through)} \longrightarrow \text{Rest (Neutral Recovery)}$$

- **Anticipation (15–25% of clip)**: Fast, exaggerated windup framing the direction of incoming force.
- **Active / Hit Frame (5–10% of clip)**: Instantaneous release reaching the strike extension. Holds for 1–2 frames to convey weight.
- **Recovery (30–45% of clip)**: Smooth deceleration with buffered input windows in the late phase.
- **Rest Invariant**: At $t = 1.0$, all bones must return to neutral $\text{CFrame.identity}$ to guarantee seamless blending into walk/run/idle states.

---

## 8. UI Design System & Interaction Invariants

### Architectural Modal Invariant
> [!IMPORTANT]
> **Single Modal Rule**: **Never permit two selection modals to be open simultaneously** (`docs/CONTEXT.md` §2). Opening any modal (Card Draft, Role Switch, Pause, Shop) must automatically close, yield, or block any other modal.

### UI Visual Elements
- **Layout Styling**: Semi-transparent dark slate backplates (`rgba(16, 20, 30, 0.85)`) framed by clean 2px cyan/amber borders and angular chamfered corners.
- **Typography**: Clean, sans-serif high-weight typography with dark drop-shadows for high readability against active horde combat.
- **Action Slots**:
  - Primary / Secondary: Centered bottom-right reticle/action cluster.
  - Z / X / C Skill Icons: Clearly showing cooldown radial sweeps and mana/gauge availability.
  - Nero Charge Gauge: Dynamic throttle bar transitioning from neutral yellow to blazing crimson as Exceed rev builds.

### Proposed UI Expansions
> [!NOTE]
> `PROPOSED` + `OWNER_DECISION_REQUIRED`:
> - Floating damage number styles (pop-up comic font with directional bounce).
> - Boss health bar styling with multi-segmented armor bars across the top screen edge.

---

## 9. Camera Language & Targeting

### Third-Person Combat Camera
- **Standard Behavior**: Over-the-shoulder third-person camera with player-controlled zoom.
- **Control Key Screen-Lock (`Ctrl`)**:
  - Pressing either `Ctrl` key toggles mouse screen-lock mode (`docs/plans/plan-03-combat.md` §4).
  - Aligns player character yaw to camera horizontal direction.
  - Crosshair highlights cyan at viewport center, compensating for GUI insets.
  - Menu opening, text editing, character death, or window focus loss instantly releases screen-lock.
- **Camera Shake Budgets**:
  - Subtle, high-frequency directional shake on heavy impact (finisher: $\le 0.12\text{s}$, amplitude $\le 0.4\text{ studs}$).
  - No continuous rumbling or nausea-inducing shake during rapid attacks (e.g. Luffy Gatling uses micro-jitter $\le 0.08\text{ studs}$).

---

## 10. Combat Feedback & Impact Hierarchy

### Multi-Sensory Hit Confirmation
Every successful hit must deliver instant, satisfying tactile feedback:
1. **Hitstop (Micro-Freeze)**: 0.04s to 0.08s momentary pause on attacker and victim animation frames on heavy blows.
2. **Directional Spark Emitters**: Sparks spray outward along the plane of the blade swing or bullet trajectory.
3. **Flash Shading**: Enemy model flashes white-tinted highlight for 0.06s.
4. **Server Confirmation**: Hit feedback is rendered only when server remote validates that the attack successfully passed all range, obstacle, and cooldown checks.

---

## 11. Audio Direction & Synchronization

> [!NOTE]
> `PROPOSED` + `OWNER_DECISION_REQUIRED`:
> The audio design system is proposed to follow synchronized anime soundscapes:
> - **Whooshes & Swings**: Tailored to weapon weight (Ichigo: low wind rumble followed by sharp whistle; Lady: pneumatic mechanical clicks).
> - **Blade Clangs & Impacts**: High-frequency metallic snaps for sword clashes; heavy bass thuds for blunt fist/fissure impacts.
> - **Sound Cue Synchronization**: Sound effects must trigger exactly at the animation `Sound_Cue` keyframe marker, never desynced from visual motion.

---

## 12. Performance Budgets & Asset Constraints

### Hard Engineering Ceilings (`COMBO-RBX-11`)
To ensure optimal performance on mobile devices and during 50+ zombie horde waves:
1. **Client VFX Controller Ceiling**: `src/client/presentation/CombatVFXController.luau` must remain strictly **under 199,000 bytes**.
2. **Triangular Budgets**:
   - Ichigo Zangetsu: $\le 1500\text{ tris}$ (current: 1480 tris).
   - Lady Launcher: $\le 500\text{ tris}$ (current: 340 tris).
   - Nero Red Queen + Gun: $\le 800\text{ tris}$ (current: 516 tris).
   - Luffy Straw Hat: $\le 500\text{ tris}$ (current: 372 tris).
   - Megumi Summons: $\le 2000\text{ tris}$ per active summon actor.
3. **Zero Orphan Instance Invariant**:
   - Every spawned Beam, Trail, ParticleEmitter, PointLight, and Sound must have an explicit lifetime capped at $\le 3.0\text{ seconds}$.
   - Cleanup must be enforced via `task.delay` and `Debris:AddItem`, with ancestry checks (`if part.Parent then part:Destroy() end`).
   - Death, unequip, or match reset must instantly flush all active player effects and temporary summon models.
