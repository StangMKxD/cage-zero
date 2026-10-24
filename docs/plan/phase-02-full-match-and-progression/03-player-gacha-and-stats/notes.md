# Notes — 03-player-gacha-and-stats

- Phase 2; รอ Phase 1 ครบก่อนเปิดรายละเอียด
- ข้อสรุปที่ตกลงแล้วอยู่ใน [accepted decisions](../../phase-01-gameplay-demo/01-cage-physics/notes.md#n-61--accepted-decision-13-outfield-base-stats-4-deferred-gk-stats-16-innate-traits-5-character-archetypes-and-body-check-target-mechanics-2026-10-24) ไม่คัดลอกหรือถามซ้ำโดยไม่มีเหตุเปลี่ยน
- Source baseline/ผลตรวจเดิมไม่ใช่ approval ของแผนใหม่

## DOCS-20261024 — Canonical Specs Alignment (2026-10-24)
- **Authority:** Owner (Stang) authorized agyplan w2:p49 to document canonical 13 Outfield Base Stats, 4 Deferred GK Stats, 16 Innate Traits, 5 Character Archetypes (65 values), and Body Check target mechanics per `HANDOFF.md`.
- **Accepted Invariants:**
  1. Base Stats bounds `0.90–1.15` mean **−10% ถึง +15%** (neutral `1.00`), NOT ±15%. Presets copied faithfully.
  2. Trait composition applies beyond base cap 1.15 for conditional effects.
  3. Ordinary Trivela is retained by everyone; `Trivela Master` grants +10% speed with single outside spin relative to normal curve (no double spin inversion).
  4. Traits are innate to characters ONLY (0, 1, 2, ... items); archetype pairs are illustrative examples.
  5. Battle Threads trait slots, trait stones, and stone trading paths are removed from Target (historical baseline preserved as labelled history). Battle Threads & Mutations are cosmetic and reward-only (VFX, Cash/EXP multiplier).
  6. TARGET bindings: LMB Shoot/Slide, E Pass/Poke, RMB Curve/BodyCheck; MMB retired. Core charging E-FakeShot exception preserved.
- **Reporting Gate Override:** Codex does not monitor/poll; agyplan presents report in own pane and waits for explicit Owner review and SEND REPORT command before messaging Codex w2:p43.

## DOCS-20261024 / Review 001 Resolution (2026-10-24)
- **Review Finding Resolutions (D-01 to D-04):**
  1. *D-01 Formulas & Rules:* Enforced strict linear inverse $BASE \times (1 - \Delta)$ (removed division); clarified Strength contact response modulation is pending exact tuning formula; removed unauthorized dribble speed penalty reduction.
  2. *D-02 7-Skill Scope Alignment:* Unified active target across Plan 03, Spec 02, Spec 03, Roadmap, Phase 1 Plan, and TDD INV-08 to 7 unique skills across 3 loadout slots (with 5 rejected animations in confirmed rework under primary HANDOFF §Q pending Owner visual review); labelled retired skills (`Drag Back & Turn 2★`, `La Croqueta 3★`) and obsolete 5/9 notes as history; clarified T-01 does not re-grill locked 13 stats.
  3. *D-03 Deferred Gates & Debug 06:* Labelled Market 6 slots and 3-second countdown as historical/proposed draft pending Phase 2 decision; explicitly stated Debug 06 implementation approval remains PENDING.
  4. *D-04 Attribution & Evidence:* Corrected Controller attribution on HANDOFF reporting gate; relative links in new fix report `docs-fix-001.md`; programmatic link/anchor and 65-value validation; noted `.sandbox/rollback/` was NOT CAPTURED / NOT INDEPENDENTLY VERIFIED.
