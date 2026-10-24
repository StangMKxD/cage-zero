# Five skill revisions — Owner-confirmed choreography

**Status:** DESIGN_CONFIRMED / REVISION_AUTHORING_AUTHORIZED / VISUAL_ACCEPTANCE_PENDING.
Owner confirmed “ได้ ยืนยัน” after the grilling summary. Confirmation authorizes creating/testing these revisions; it is not acceptance of their eventual appearance or closure of any plan.

## Authority and boundaries

- Scope: HeavyKnockOn, OpenUpFakeShot, BodyFeint, HeelChop, Elastico. Their inspected versions were rejected. Preserve those versions/history; author distinct revisions with real IDs and provenance.
- Primary assignment: [HANDOFF](../HANDOFF.md) latest§Q; [tasks](../../tasks.md) T18. Same sole implementer agycage; Codex independently reviews; push reports under§O, no polling.
- LaneChange/Sombrero retain their prior status, not implied accepted. Keep separate core E-triggered FakeShot and F36–38 corrections; OpenUpFakeShot1★ is a loadout skill, not that core action.
- Keep single custom R6,7 unique active skills/3slots/star ceiling and existing action authority/input policy. No rig/card/stat redesign, personal animation packs, global ball-physics changes, new skills or bindings, upload/publish/Git/extra agents.

## Common confirmed behavior

- Skills cause a short actual body movement automatically; the player need not hold movement just to make the skill read. Joint motion alone is not proof of the intended world movement.
- HeelChop is the explicit exception to following the ball: grounded body weight shift/leg spread near its starting position, no jump and no horizontal chase after the outgoing ball.
- Side-directed variants mirror feet, body and ball path. Keep existing shared character-relative direction/Server-validation conventions; select the intended side at activation. No world-X or camera-yaw sign hacks. HeavyKnockOn retains its forward/run-direction policy.
- Contact must be legible: weight-bearing/support leg, contacting foot, actual ball response and exit pose agree. Keep R6 feet/legs clear of ground/interpenetration and transitions into ordinary movement smooth.
- Real body/ball motion in gameplay must match the preview choreography/contact phases. A managed preview ball is allowed for readability but must be labelled a preview prop, not used as proof of actual gameplay ball behavior.
- Preserve tackleability, ball-contact/ownership/range, stamina/cooldown/recovery, intent/generation/replay/reset/death gates. No teleport/weld/anchor/invulnerability/automatic possession or successful dodge. Body displacement must use a bounded authoritative existing movement seam, not a trusted arbitrary client displacement.
- Exact seconds/studs/angles are NOT Owner-approved constants in this interview. Use traceable configurable draft tuning based on current conventions, measure actual outcomes and expose tuning in the preview. Do not silently change cooldown/cost/shot/pass balance to make a clip pass.

## 1. HeavyKnockOn — short knock and one small acceleration

**Owner's defect:** running then pressing the skill looked like nothing happened; the ball stayed with the player.

1. Show a readable support/weight transfer and forward foot contact.
2. Touch the ball ahead a SHORT distance, visibly outside its unchanged ordinary dribble position.
3. Apply ONE short body acceleration/following segment, only a little faster than the current running motion. No repeated burst or long launch.
4. Blend back into the ordinary run; ordinary valid contact/collection governs subsequent control. The ball must not be glued or immediately pulled back so the contact disappears.

**Acceptance:** from an already-running player, skill-on vs ordinary running visibly differs in both ball lead and the single short burst; record ball/player positions over subsequent frames. Preserve opponent opportunity to contest the ball; no guaranteed recapture.

## 2. OpenUpFakeShot — shot feint, open hips, diagonal touch

1. Clearly suggest the start of a shot with leg/hip/body preparation.
2. Check that feint and open the hips.
3. Make the real foot contact and touch the ball diagonally forward toward the selected exit.
4. Automatically take a short step after the ball, then blend into locomotion.

**Acceptance:** feint/open/contact/exit are individually readable as one flowing skill. Mirror both sides. Do not substitute the core E FakeShot or a generic body swivel; no unintended real Shoot/Pass from the feint.

## 3. BodyFeint — body deception first, ball exit second

1. Shoulder and hip sell a feint opposite the intended exit with a small weight shift.
2. During that initial deception, the ball stays between/near the feet rather than following the false shoulder direction.
3. Transfer weight, contact the ball and touch it toward the actual selected exit.
4. Automatically take a short exit step and regain the run stance.

**Acceptance:** viewer can distinguish the false body direction from the ball's actual exit. Both sides are mirrored; body actually shifts/steps, not a tiny stationary shoulder twitch.

## 4. HeelChop — grounded cross-foot cut, body does not chase

**Latest correction:** NO JUMP. The earlier jump/straddle wording is superseded. Direction is chosen first. The contacting foot is opposite the selected ball exit, and itself hooks/cuts the ball around the other/supporting leg.

| Selected movement | Contacting foot | Ball path | Body exit |
|---|---|---|---|
| A / left | RIGHT | Right foot cuts/hooks around left/support leg, ball exits LEFT beside the player | Grounded leg spread/weight shift near starting point; no chase left |
| D / right | LEFT | Left foot cuts/hooks around right/support leg, ball exits RIGHT beside the player | Mirrored grounded weight shift; no chase right |

Phases: select side → readable leg spread/cross-body preparation → the opposite foot itself contacts and cuts around the other leg → ball travels beside the body → foot plants/body balances near the initial position.

**Acceptance:** A uses right foot and ball goes left; D uses left foot and ball goes right. No hopping/airborne jump transition and no automatic body pursuit of the outgoing ball. The ball path/contact is visible; not just two legs spreading while a prop moves independently.

## 5. Elastico — continuous two contacts with the same foot

1. The contacting foot/body sell an outward ball direction.
2. The SAME foot immediately snaps/cuts the ball back toward the actual exit as one continuous movement, with no artificial stop between two separate taps.
3. Body weight follows the true exit and produces a short automatic exit step.
4. Mirror the opposite variant using the corresponding foot; each variant still uses one foot for both contacts.

**Acceptance:** both ball-direction changes and both contacts are legible, including the deceptive first direction. Foot/body/ball do not contradict each other; no generic one-stage lateral cut labelled Elastico. Preserve existing Elastico gameplay catalog ID; revision IDs remain distinct.

## Delivery and per-skill review gate

1. Preflight actual current source/status, Motion connection, exact Cage-Zero137721422246269 Studio, managed R6 and dirty editor state. Do not overwrite user drafts or use historical session IDs as selectors.
2. Author one distinct new editable revision per rejected skill; preserve old clips/provenance and accepted baselines. Link current source/recipe IDs/direction/phases/markers/full generated hashes in the single animation-library.json or its existing scoped delta until merged; no duplicate full manifests.
3. Verify open/play/stop/scrub and pose/body/preview-ball choreography where available. Record actual blocked/manual UI steps rather than counting queued jobs or schema validation as visual success.
4. Verify runtime coupling with current source/input/Server/actual player+ball over time, especially HeavyKnockOn separation and HeelChop opposite-foot/no-chase behavior. Keep deterministic tests and live/visual results clearly separate; meaningful targeted regression for affected shared movement/contact/animation lifecycle.
5. Present the five revisions as individually selectable OWNER_REVIEW_PENDING items. Owner reviews each skill before promotion to the accepted/current set. Do not overwrite/promote the rejected active baseline merely because a schema/test passed. Prototype integration must remain reversible and identified as review work.
6. Reuse the next available Plan03 correction report, cross-link shared evidence once, full hashes generated as untruncated strings/JSON. Push a concise READY_FOR_REVIEW/BLOCKED/NEEDS_OWNER_ACTION report to verified Codex destination per§O. No self-approve/close/commit/push/publish.
