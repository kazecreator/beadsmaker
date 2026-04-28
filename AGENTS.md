# BeadsMaker Development Rules

## Source of Truth

- The BeadsMaker PRD source of truth is:
  `/Users/kevinzhang/Downloads/# BeadsMaker Codex Workspace (Single File).md`
- Read the PRD before making product, UI, architecture, or behavior changes to BeadsMaker.
- Treat the latest PRD content as authoritative for BeadsMaker scope and direction.

## Iteration Rules

- Every BeadsMaker iteration must update the PRD when behavior, scope, UI, architecture, supported languages, or product rules change.
- If a requested change conflicts with the PRD, pause and discuss the conflict before editing code.
- Do not silently expand beyond the PRD. If an extra feature seems useful, propose it first.

## Product Principles

- Creation-first.
- Community supports creation, not dominates it.
- Guest-first and weak-login.
- Export is the bridge to real-world crafting.
- No making steps.
- No progress bars or progress-style crafting UX.
- No forced login and no unique username at onboarding.

## Active Project Focus

- Default active app: `BeadsMaker.xcodeproj` with the `BeadsMaker` scheme.
- Active source root: `BeadsMaker/`.
- The previous BeadMaker legacy app has been removed from this workspace; do not reintroduce it unless explicitly requested.
