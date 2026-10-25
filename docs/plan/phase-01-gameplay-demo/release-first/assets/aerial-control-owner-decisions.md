# Owner design delta — Assisted Aerial Control & Trajectory Guides

2026-10-25 · Owner Stang answers: Q1 recommended, Q2 B, Q3 recommended(B), Q4 recommended(A). Accepted design decisions only; no runtime implementation authorization or test results.

## Accepted behavior

1. **Contact-gated aerial reception:** A player jumping or Wall Launching may acquire airborne possession and prepare a shot after actual contact with the ball hitbox, if player-ball relative approach speed is within the tunable reception limit. Excessive relative approach speed causes deflection/loose ball instead. This is not a minimum player sprint-speed unlock. Server validates contact and reception; no remote/distant teleport into possession.
2. **Brief aerial aiming hold:** On successful reception, briefly suspend the player in air to allow aiming/windup, then resume descent. This explicitly supersedes always-fall-normally for this assisted action. Ordinary movement/contact remains governed by the action lifecycle; ball must remain visible and contestable. Existing no-I-frame/no-guaranteed-skill-win rules remain. Do not silently add unlimited flight or repeated stall chaining.
3. **Live trajectory + landing marker:** All players can see the airborne ball's predicted curved trajectory and landing point, including predicted wall/ceiling rebounds. Recompute when ball state/trajectory changes. The shooter additionally sees predicted aim trajectory/landing point while winding up before release. Prediction is visual guidance, not a force or guaranteed future outcome. A touch, interception or moving obstacle may invalidate it; update/clear stale guides appropriately.
4. **Goalkeeper skill through contact:** A goalkeeper must reach the right position at the right time and physically contact the ball within valid reach to save it. Correct direction alone does not guarantee a save. The idea supports readable counterplay; it does not promise every shot is saveable from any position or automatically add goalkeeper AI to launch scope.

## Supersession and integration

- Prior blanket no-auto-catch text now has an explicit exception: contact-and-speed-gated assisted aerial reception above. Preserve the prohibition on distant possession/teleport and distinguish ordinary ground trapping. Do not remove every ball-possession safeguard.
- RF02 owns aerial reception/possession/charge/hang lifecycle and live curved-ball guidance; RF04 integrates Wall Launch entry and rebound prediction; RF06 provides HUD/markers/camera presentation and multiplayer visibility. Goalkeeper behavior remains with the appropriate deferred goalkeeper scope unless Owner separately changes launch requirements.
- R15 avatar dimensions stay standardized. Apply server authority, visible ball hitbox, stamina/recovery contracts and no per-move cooldown. Do not invent new costs, mandatory buttons or paid effects.

## Tuning and unresolved technical design

Exact relative-speed threshold, hitbox tolerance, hold duration, release/resume momentum, re-entry protection, aerial possession ending on landing/loss, and predictive horizon/accuracy/performance budgets need a bounded technical contract and empirical tuning. Existing values are baseline candidates, not implicitly approved new constants. Preserve server/client ownership separation; cosmetic client prediction cannot grant possession or saves.

Before implementation, define a finite state/cleanup contract for contact success/failure, hold, shot/pass release, contested ball, landing, wall collision, death/respawn/disconnect and stale network events. Enforce finite hold across repeated contacts without adding gameplay cooldown by another name. Source of truth for preview/live prediction must match supported ball/curve/collision rules; no invented perfect simulation guarantee.

## Acceptance to add to plans

- Jump/WallLaunch contact within speed limit permits aerial possession and windup; excessive approach speed does not capture; remote spoof cannot capture without contact.
- Hold is visibly brief and bounded; aim/release/descent transitions are coherent; opponents can contest during hold; reset/disconnect cannot leave flight/possession stuck.
- Before-release preview appears to shooter; live trajectory/landing guide appears to all players, handles supported curves/rebounds and refreshes after actual deflections/interceptions.
- Goalkeeper direction without reach/timing is not an automatic save; actual valid contact can save under the selected goalkeeper rules.
- Owner visual UAT validates readability/ease of use, with multi-client evidence; document prediction limits rather than claiming exact outcomes.
