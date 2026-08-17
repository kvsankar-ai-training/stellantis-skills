---
name: stellantis-tdd-codegen
description: 'Implement a feature or fix using strict Test-Driven Development (Red/Green/Refactor), delegating test-writing and implementation to two separate subagents so neither can see or bias the other''s work: a test-writer subagent drafts failing tests from the spec (Red), a coder subagent then writes the minimal code needed to make those exact tests pass (Green) without editing the tests, then the code is refactored for readability/simplicity while keeping tests green, and finally additional unit tests (edge cases, error paths) are added as the last step. Use when asked to build a feature test-first, follow TDD/red-green(-refactor), "write the tests first", or implement code against an existing SRS/SDD/acceptance-tests with verifiable, test-backed increments. DO NOT USE FOR exploratory prototyping, spike/throwaway code, or when the user explicitly wants tests written after or alongside the implementation rather than first.'
argument-hint: 'A feature/fix description or a spec (SRS/SDD/acceptance tests) to implement, the target codebase location, and the test framework/runner in use'
---

# Test-Driven Code Generation (Red / Green / Refactor)

Act as a disciplined TDD practitioner who never lets implementation details leak into test design and never lets test design leak into implementation. You orchestrate two independent subagents — one that only writes tests, one that only writes code — and you are the sole party that runs the test suite and judges red/green state between them.

## When to Use

- The user wants a feature or bug fix built strictly test-first, following Red/Green/Refactor.
- There is enough of a spec (explicit requirements, an SRS/SDD, acceptance criteria, or a clear description from the user) to derive concrete test cases from before any code exists.

Do not use this skill for throwaway spikes/prototypes, or when the user wants tests written after the code. If the user's request is too vague to derive concrete test cases (no acceptance criteria, no described behavior), ask clarifying questions before starting Phase 1 — don't invent behavior to test against.

## Phase 0: Establish the Contract

Before dispatching any subagent, pin down what both of them will be told, since they must never see each other's private reasoning or drafts mid-flight:

- The precise scope of the unit of work (one feature/fix, not a whole system) — keep it small enough to cycle through Red/Green/Refactor in one pass.
- The observable behavior/spec: inputs, outputs, error conditions, edge cases already known from the user or source documents (SRS, SDD, acceptance tests). Quote or summarize the relevant spec text so the test-writer isn't guessing.
- The language, test framework/runner, and file/module layout conventions already used in the repo (check existing tests for naming and structure conventions before writing the prompt).
- The public interface/contract the code must expose (function/class/endpoint signatures) if the user or spec already fixes it. If not fixed, let the test-writer subagent propose the interface as part of writing tests — the interface emerges from the tests, not the other way around.

## Phase 1: RED — Delegate Test Writing

Dispatch a subagent (via `runSubagent`) whose **only** job is to write failing tests. In the prompt:

- Give it the scope, spec, framework, and conventions from Phase 0.
- Explicitly instruct it to write tests only — no implementation code, no stub/production files beyond what's needed for the test file to compile/import (e.g., an empty function signature or `NotImplementedError`/`throw new Error('not implemented')` stub is acceptable only if the language requires something importable; it must not contain real logic).
- Instruct it to cover the normal/happy path first, plus the edge cases and error conditions already known from the spec — but tell it explicitly that additional edge-case tests come later (Phase 5), so it shouldn't try to be exhaustive yet.
- Ask it to report back: the test file path(s), the interface/contract it assumed (function signatures, types, module paths), and the exact command to run the tests.

After the subagent returns, **you** run the tests yourself (do not trust the subagent's claim that they fail). Confirm:

- The tests fail for the *expected* reason (missing implementation / assertion failure), not because of a syntax error, import error, or misconfigured test runner. A red bar for the wrong reason must be fixed before moving on — either by you directly for trivial config/import issues, or by re-dispatching the test-writer subagent for actual test-logic problems.

## Phase 2: GREEN — Delegate Minimal Implementation

Dispatch a second, independent subagent whose **only** job is to make the failing tests pass. In the prompt:

- Give it the scope and spec from Phase 0, the exact test file path(s) and the run command, and the interface/contract the tests assume (from Phase 1's report).
- Explicitly instruct it: do not modify the test files (only production/implementation code); write the minimal code needed to make the given tests pass — no speculative features, no handling for cases the tests don't exercise, no gold-plating.
- Ask it to report back which files it changed/created and confirmation it ran the tests itself.

After it returns, **you** run the full test suite yourself. If any test still fails:

- Diagnose whether the failure is an implementation gap (re-dispatch the same coder subagent with the specific failing test output and a narrower instruction) or a flaw in the test itself (re-dispatch the test-writer subagent to fix the test, keeping the coder subagent's code untouched in that round).
- Repeat until every test passes (green) — do not proceed to refactoring on a red suite.

## Phase 3: REFACTOR — Improve Without Changing Behavior

With all tests green:

- Review the implementation for readability and simplicity: remove duplication, clarify naming, simplify control flow, extract or inline as appropriate — but change nothing about observable behavior or the public interface the tests rely on.
- You may do this refactor yourself or dispatch the coder subagent again with an explicit "refactor only, tests must stay untouched and still pass" instruction.
- Re-run the full test suite after every refactor step. If a refactor breaks a test, that's a signal the refactor changed behavior — revert or fix immediately rather than adjusting the test to match.
- Keep refactors proportional to the size of the unit of work from Phase 0 — this is cleanup of what was just built, not a broader rewrite.

## Phase 4: Add Additional Unit Tests (Last Step)

Only after refactoring is complete and the suite is green:

- Dispatch the test-writer subagent (or write directly, if trivial) to add further unit tests covering edge cases, error paths, and boundary conditions not exercised in Phase 1 — informed by the final implementation's actual branches/conditions, not just the original spec.
- Run the full suite again. Any new test that fails reveals a real gap: return to a mini Red→Green cycle (Phase 1 diagnosis → Phase 2 fix) for just that gap rather than weakening the new test.
- Finish only when the full suite — original tests plus the newly added ones — passes.

## Reporting Back to the User

Summarize concisely: what was built, the test file(s) and production file(s) touched, the final test run result (pass count), and any assumptions made about ambiguous spec details in Phase 0.
