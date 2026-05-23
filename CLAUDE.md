# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Lean 4 / Mathlib formalization of the **CRAM/DKAM** discrete Navier–Stokes framework on the 3-torus. The target is a "curve of infinite descent" continuum bridge: extracting a Leray–Hopf weak solution of 3D incompressible NS as the limit of an exact-integer discrete scheme. The formalization is a skeleton — most theorems are stated with the intended signature and closed with `sorry`, tagged by gap IDs (see below).

- Lean toolchain: `leanprover/lean4:v4.14.0` (pinned in `lean-toolchain`)
- Dependency: Mathlib pinned at `v4.14.0` (in `lakefile.toml`)

## Build

```bash
lake build              # build all (default target: NSTorus)
lake build NSTorus.DKAM # build a single module
lake env lean NSTorus/Lemmas.lean   # typecheck one file directly
```

The first build fetches and compiles Mathlib — expect it to take a long time. `.lake/packages/` and `.lake/build/` are gitignored.

There is no test framework: correctness is whatever the Lean kernel accepts. A module is "passing" when it elaborates without errors (warnings about `sorry` are expected and intentional).

## Architecture

The formalization follows a strict DAG (described in `NSTorus.lean`). Modules must be understood in this order because each relies on the signatures above it:

1. **`NSTorus/Axioms.lean`** — A1–A6. Foundational axioms stated as Lean `axiom` declarations (often with `True` placeholders for the body; the mathematical content is carried by the *name* and docstring, with computational verification living outside this repo in the QMNF technical docs). A3 (skew-advection energy neutrality) and A5 (discrete diffusion non-positivity) carry real content; the rest are placeholder stubs.
2. **`NSTorus/Definitions.lean`** — D1–D6. `DiscreteVelocityField N := Fin N → Fin N → Fin N → ℤ × ℤ × ℤ` is the central type: exact-integer divergence-free velocity on an N³ grid. `discreteEnergy`, `discreteDissipation`, `discreteTimeDeriv`, `liftingOperator` (piecewise-constant lift ℤ→ℝ), `CurveOfInfiniteDescent`.
3. **`NSTorus/Lemmas.lean`** — L1–L3. Exact energy identity (L1 ← A3,A4,A5), uniform L²/H¹ bounds (L2 ← L1), time-derivative bound in H⁻¹ (L3 ← L2).
4. **`NSTorus/Compactness.lean`** — T1–T4. Weak compactness (Banach–Alaoglu), strong compactness (Aubin–Lions–Simon), nonlinear passage to the limit, and the continuum-bridge theorem `continuumBridge`.
5. **`NSTorus/DKAM.lean`** — Subcriticality `deg(S)=2 < ρ(B)=3` and the D-030 winding-energy bound `‖ω‖_∞ ≤ (p−1) + √E(0)`. Depends only on `Definitions`.

`NSTorus.lean` (the root) imports these five in order and is the default build target.

## Conventions specific to this repo

- **`variable (N : ℕ) [NeZero N]`** is threaded through every module. The `NeZero N` instance is what lets `Fin N` index-arithmetic like `(j.val + 1) % N` produce a valid `Fin N` via `Nat.mod_lt _ (Nat.pos_of_ne_zero (NeZero.ne N))`. Reuse this idiom rather than inventing new positivity proofs.
- **Integer-first.** Energy and dissipation are `ℤ`-valued (the factor of ½ in energy is absorbed — we track `2·E`). Do not add floating-point or `ℝ` arithmetic on the discrete side; per A1 the integer layer is the critical path. ℝ only appears after `liftingOperator`.
- **Gap tagging.** Every `sorry` is preceded by one or more comments of the form `[GAP <ID>]` or `[GAP <ID>-<letter>]` (e.g. `[GAP L1-a]`, `[GAP D-024]`, `[GAP T2-c]`). When adding a new unproved step, follow this pattern — pick a fresh ID tied to the theorem it sits under, and keep the English sketch of the intended proof step on the same line. The four **named open gaps** (D-016, D-024, D-026, D-030-A/B) are listed in the root-module docstring and are considered load-bearing; do not silently close or rename them.
- **Axiom naming.** `A<n>_camelCaseDescription` (e.g. `A3_skewAdvectionNeutral`). Each axiom's docstring cross-references the QMNF source (e.g. `QMNF ref: AXIOM EB-A5`).
- **Theorem statements first, proofs later.** Many theorems have genuine signatures but trivial witnesses (`∃ ..., True`) flagged as `[STATEMENT SKELETON]`. When strengthening a statement, update the docstring's proof sketch in lock-step — future Claudes rely on the sketch when filling gaps.

## When filling a `sorry`

1. Read the `[GAP …]` comments directly above it — they are the proof outline.
2. Check whether the statement is a real one or a `True` placeholder; strengthening the statement is often a prerequisite and should happen in the same change.
3. Respect the DAG: a proof in `Compactness.lean` may cite `Lemmas.lean` and `Axioms.lean` but never the reverse.
