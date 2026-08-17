---
name: stellantis-design-create
description: 'Create a Software Design Document (SDD) from an existing SRS/requirements or a rough feature idea, delivered as a self-contained HTML document with rendered component, sequence, and deployment diagrams, capturing key decisions as Architecture Decision Records (ADRs) including explicit tech stack choices (language/runtime, framework(s), datastore only if one is actually needed, key libraries), the simplest design that solves the problem (no over-engineering), whichever boundary contracts the system actually has (an OpenAPI spec for an HTTP API, a UI/component contract for a frontend, a CLI argument spec for a tool, a public API surface for a library — only produced when that boundary applies), a data boundary only when the system owns persisted data, a functional-core/imperative-shell internal architecture honoring loose coupling and Single Responsibility, component-level tests derived from acceptance tests (ATs) plus the design, and a traceability matrix linking design elements back to use cases/requirements. Applies to any kind of system — backend services, frontend/UI apps, mobile apps, CLIs, libraries/SDKs, or full-stack systems — not backend-only; the applicable boundary/data/deployment artifacts are derived from what the system actually is, never assumed. Use when asked to create, write, draft, or scaffold a design document, technical design, architecture doc, SDD, or when asked to produce ADRs, choose/document a tech stack, an API/UI/CLI/library contract, a database schema (if applicable), architecture diagrams (component/sequence/deployment), component-level test plans, or a design-to-requirements traceability matrix. DO NOT USE FOR eliciting/writing product requirements (use stellantis-srs-create instead) and do not use for reviewing an already-written design (that is a separate review activity).'
argument-hint: 'An SRS/requirements doc (ideally with Acceptance Tests) or a rough description of the feature/system to design (state the kind of system — backend service, frontend/UI, mobile, CLI, library, or full-stack — if not obvious), and optionally target file paths for the SDD, ADRs, contract spec(s), schema, and component-test doc'
---

# Software Design Creation

Act as a senior software architect turning requirements (or a rough idea, if no SRS exists) into a lean, well-bounded technical design: an HTML Software Design Document (SDD) with rendered diagrams, a set of Architecture Decision Records (ADRs), whichever boundary contract(s) the system actually has, a data schema if the system owns persisted data, component-level tests, and a traceability matrix. This skill is system-type-agnostic: it applies equally to backend services, frontend/UI apps, mobile apps, CLIs, libraries/SDKs, and full-stack systems — never assume a backend HTTP service is being designed unless the requirements say so.

## When to Use

- Requirements exist (an SRS, or a short description) and the next step is deciding *how* to build it — for any kind of system, not just a backend service.
- The user explicitly asks for a design doc, technical design, architecture, ADRs, a boundary contract (API/UI/CLI/library), a DB schema, architecture diagrams, component-level tests, or a traceability matrix.
- The user wants key technical decisions captured durably (as ADRs) rather than left as chat history.

If an Acceptance Tests document exists from `stellantis-srs-create`, read it before drafting — component-level tests (Phase 10) and traceability (Phase 11) both depend on it.

Do not use this skill to elicit or write product requirements — that's `stellantis-srs-create`. If no requirements exist yet and the user is only describing a rough idea, briefly confirm scope before designing rather than re-running a full requirements interview.

## Phase 1: Understand the Problem Before Designing

- Determine the **kind of system** being designed before anything else: a backend/API service, a frontend/UI application, a mobile app, a CLI tool, a library/SDK, an embedded/desktop app, or a full-stack system spanning several of these. This is not an assumption to default on — infer it from the SRS/requirements, or ask the user directly if it isn't stated. Every later phase (tech stack, boundary contracts, data boundary, diagrams) is scoped to this answer, not to a backend-service template.
- Read the SRS/requirements if one exists; otherwise ask enough clarifying questions (one at a time) to pin down: core entities, the primary use cases/workflows, expected scale, and any hard constraints (existing systems to integrate with, mandated tech, compliance).
- Identify what's genuinely in scope for *this* design pass. Do not design for hypothetical future requirements that aren't in the SRS — that's over-engineering (see Phase 2).
- Confirm the deployment/runtime shape if it isn't obvious (single service, modular monolith, multiple services, a client-only app with no server component, a distributed CLI/library with no deployment at all) — this affects every downstream artifact. Default to the simplest shape that fits the system kind identified above unless the requirements or constraints clearly demand more.

## Phase 2: Simplicity First — No Over-Engineering

This is a standing constraint across every artifact produced, not a one-time checklist item:

- Design for the requirements that exist today, not for speculative future scale, extensibility, or requirements that "might" show up. YAGNI applies to architecture as much as to code.
- Prefer the smallest number of moving parts that correctly solves the problem: fewer services over more, a single database over multiple, synchronous calls over async/event-driven infrastructure unless the requirements need it (e.g., genuine decoupled scaling, long-running work, or an NFR that demands it).
- Every piece of infrastructure, abstraction layer, or pattern introduced must be traceable to a concrete requirement or constraint. If you can't say *which* requirement justifies it, cut it.
- Prefer boring, well-understood technology over novel choices unless there's a documented reason (see ADRs, Phase 3).
- When a simpler alternative was considered and rejected, say so explicitly in the relevant ADR rather than silently picking the more complex option.

## Phase 3: Architecture Decision Records (ADRs)

Capture every key decision as its own ADR — a decision is "key" if reversing it later would be costly (choice of datastore, sync vs. async communication, monolith vs. services, auth approach, major library/framework choice, a rejected simpler alternative, etc.). Don't write an ADR for reversible, low-cost choices (e.g., a variable naming convention).

- One ADR per decision, in its own file, numbered sequentially: `NNNN-<slug>.md` (e.g., `0001-use-postgres-for-primary-store.md`).
- Use this template for every ADR:

```markdown
# NNNN. <Decision Title>

Date: YYYY-MM-DD
Status: Proposed | Accepted | Superseded by NNNN

## Context

<The problem/forces at play. Why does a decision need to be made here?>

## Decision

<The decision, stated as a single clear sentence: "We will ...">

## Alternatives Considered

<Each alternative considered, including the simplest one if it was rejected, and why it was rejected.>

## Consequences

<What becomes easier or harder as a result. Include trade-offs honestly - a good ADR names the downsides too, not just the upsides.>
```

- Status starts as `Proposed` unless the user confirms it's already decided/final, in which case use `Accepted`.
- If a later ADR reverses an earlier one, don't edit history — add a new ADR and mark the old one's status `Superseded by NNNN`.
- The SDD references ADRs by number/link rather than restating their reasoning inline — keep the reasoning in one place.

## Phase 4: Tech Stack Decisions

The technology stack is itself a set of key decisions, not an assumed given — decide and document it explicitly rather than defaulting silently to whatever's familiar, and rather than defaulting to a backend-service stack when the system kind (Phase 1) is something else:

- Cover, at minimum, whichever of these actually apply to the system kind identified in Phase 1: language(s)/runtime, framework(s) (a UI framework for a frontend, a mobile framework for an app, a web framework for a backend service, an argument-parsing library for a CLI, or none at all for a plain library), a datastore (only if the system actually owns persisted state — a frontend-only app or a CLI/library frequently has none of its own), messaging/queueing (only if a requirement demands it), key libraries for cross-cutting concerns (auth, validation, logging/observability, state management), and the testing stack (unit/integration/e2e test frameworks as relevant).
- Each non-trivial stack choice gets its own ADR (Phase 3) — e.g., "why this language/runtime," "why this framework," "why this datastore (if any)" — following the same Context/Decision/Alternatives/Consequences template, including the simpler or more familiar alternative if one was rejected.
- Ground every choice in the requirements/constraints from Phase 1 (team familiarity, existing systems to integrate with, target platform/runtime environment, performance/scale NFRs) rather than personal preference or novelty — simplicity (Phase 2) applies here too: prefer a stack the team already knows over a new one unless there's a documented reason to introduce it.
- Pin down concrete choices, not categories — "PostgreSQL 16", "React 18", and "ASP.NET Core" are decisions; "a relational database" and "a modern framework" are not.
- Note version/compatibility constraints only where they materially affect the design (e.g., a minimum language version required for a language feature the functional core relies on, or a minimum OS/browser version for a client app) — don't pad the section with a routine dependency list that belongs in a lockfile, not the SDD.
- The SDD's Tech Stack section (Phase 12) summarizes the chosen stack in one table (Concern / Choice / ADR) and links to each ADR for the reasoning; it does not restate the ADR's Alternatives/Consequences inline.

## Phase 5: Boundary Contracts

Every system exposes at least one boundary contract to something outside itself — but *which kind* depends entirely on the system kind from Phase 1; never default to an HTTP API when the system doesn't have one. Produce whichever of these actually apply, and skip the rest explicitly (state "not applicable" rather than silently omitting):

- **HTTP API** (a backend service, or any component exposing one to other services/clients): define it as an OpenAPI (3.x) spec, not just prose. Define every endpoint's path, method, request/response schemas, status codes (including error responses), and auth requirement. Use `components/schemas` for shared shapes rather than duplicating inline. Model errors explicitly via a consistent, reused error shape.
- **UI/component contract** (a frontend or mobile app): define the boundary as the set of screens/views/components and their contracts — props/inputs, emitted events/outputs, and the external API(s) or data sources they consume (linking to that API's own OpenAPI spec if it's a separate system, or noting it as an external dependency if it isn't part of this design).
- **CLI contract** (a command-line tool): define the boundary as the command/argument/flag/subcommand surface, including inputs, outputs (stdout/stderr shape, exit codes), and configuration sources.
- **Public library/SDK surface** (a library): define the boundary as the public API — exported types/functions/classes, their signatures, and versioning/compatibility guarantees (e.g., semver contract).
- **Event/message contract** (any system kind, only if messaging is in scope per Phase 4): define the event/message schemas exchanged.
- Keep whichever contract(s) apply scoped to what's actually needed for the requirements in play — don't pre-design surface area for features that aren't in scope yet.
- The contract file(s) are the source of truth: the SDD should describe the boundary's *purpose and shape* in prose and link to the spec/contract for authoritative detail, not duplicate every field.

## Phase 6: Data Boundary — Persisted State (If Any)

Only produce this artifact if the system actually owns persisted state of its own — many frontend-only apps, CLIs, and libraries own none, relying entirely on an external API or the host environment; in that case, state explicitly in the SDD that there is no owned data boundary and note where persistence actually lives (an external service, browser local storage owned by another layer, the caller's own storage) instead of fabricating a schema to fill the section.

When the system does own persisted state, define the persistence boundary explicitly as a schema, not just an entity list in prose:

- Produce a concrete schema: tables/collections, columns/fields with types, primary/foreign keys, indexes, and constraints (uniqueness, not-null, check constraints) that enforce invariants at the data layer where practical.
- Use the format matching the target datastore (SQL DDL for a relational store; a JSON-schema-like document shape for a document store; a versioned client-side schema for structured local/offline storage) — pick the format based on the ADR that decided the datastore choice.
- Model relationships and cardinality explicitly (one-to-many, many-to-many with a join table, etc.).
- Note ownership: which service/module/app owns which tables/stores if there's more than one deployable — data owned by two components across a boundary is a coupling smell to flag, not silently allow.
- Keep the schema traceable to entities/use cases in the requirements; don't add speculative tables/columns for unrequested features.

## Phase 7: Diagrams

Every SDD must include at least these three diagram types, authored as Mermaid so they render live in the HTML output (Phase 12) instead of being static images that drift out of sync:

- **Component diagram**: the major components/modules/services and the dependencies between them (`graph` or `flowchart`). Direction of arrows should match the dependency direction discussed in Phase 8 (Loose Coupling) — a component pointing at another it doesn't actually depend on is a bug in the diagram, not a stylistic choice.
- **Sequence diagram(s)**: one per significant use case/workflow (`sequenceDiagram`), showing the actor and the components/services/screens involved, and any calls across the boundary contract(s) from Phase 5 and into the persistence layer from Phase 6 (if either applies). Don't produce one sequence diagram per trivial CRUD endpoint or passthrough screen — cover the workflows that actually have multiple participants or branching, and note in prose which use cases share a simple, undiagrammed flow.
- **Deployment diagram**: the runtime topology (`graph` with subgraphs, or `C4Deployment` if the Mermaid version supports it) — scoped to whatever the system kind (Phase 1) actually deploys as: processes/containers and datastore(s) with network boundaries for a backend service; hosting/CDN and target browsers/devices for a frontend or mobile app; the distribution/runtime environment (package registry, target OS/runtime) for a CLI or library, which may be a very small diagram or a short prose note if there's genuinely no topology to draw. Keep this as simple as the actual deployment shape decided in Phase 1/ADRs; don't invent infrastructure (load balancers, caches, queues, servers) that no ADR or requirement calls for.
- Each diagram gets a one- or two-sentence caption stating what it shows and, where relevant, which ADR or use case it corresponds to — a diagram with no caption forces the reader to reverse-engineer its purpose.
- Keep diagrams scoped to the deployment shape chosen in Phase 1 — a single-service design should produce a correspondingly simple component/deployment diagram, not an elaborate one padded out for appearance.

## Phase 8: Design Principles

Apply and explicitly call out adherence to these principles in the SDD's internal design section — don't just assert compliance, show it in the component/module breakdown:

- **Single Responsibility Principle**: each module/class/service has one reason to change. When describing components, state each one's single responsibility in one sentence; if it takes more than one sentence or an "and", it's a signal to split it.
- **Loose Coupling**: components depend on abstractions/contracts (a boundary contract from Phase 5, an interface, an event schema) rather than each other's internals. Prefer dependency direction pointing toward stable abstractions. Flag any place two components would need to change together as a coupling risk.
- **High Cohesion**: related behavior and data stay together; don't scatter logic for one concept across many unrelated modules.
- **Explicit Dependencies**: a component's dependencies are visible (constructor/parameter injection, explicit imports) rather than hidden (globals, service locators, hidden singletons).
- Apply other SOLID principles (Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) where relevant, but don't force-fit them where they don't add value — simplicity (Phase 2) still wins over pattern-for-pattern's-sake.

## Phase 9: Functional Core, Imperative Shell

Structure the internal architecture of any non-trivial component using this pattern:

- **Functional core**: pure business logic/domain rules — functions with no I/O, no mutation of external state, and no side effects. Given the same inputs, always the same outputs. This is where domain rules, calculations, validations, and decisions live, and where most unit tests should target.
- **Imperative shell**: a thin outer layer that handles I/O (DB calls, HTTP calls, filesystem, UI rendering/DOM updates, clock, randomness) and orchestrates calls into the functional core. The shell decides *when* and *with what data* to call the core, but contains as little logic as possible itself.
- In the SDD, show this split concretely: name the core modules/functions (pure) versus the shell modules (I/O-handling), and note the direction of dependency (shell depends on core, never the reverse).
- This is what makes the design testable without heavy mocking: the functional core is tested directly with plain inputs/outputs, and the shell is tested with a thin layer of integration tests instead of exhaustively unit-testing I/O paths.
- Don't force a functional core split onto trivial CRUD passthroughs with no real logic — apply it where there's actual domain logic to isolate; forcing it everywhere adds ceremony without benefit (Phase 2 still applies).

## Phase 10: Component-Level Tests (from ATs + Design)

Derive a component-level test plan by combining the Acceptance Tests (Given/When/Then, from `stellantis-srs-create`) with the internal design (Phase 8 components, Phase 9 core/shell split):

- For each AT, identify which component(s) it exercises and split it into the component-level tests actually needed to prove it: a **functional core test** (pure input/output, no mocking, covers the domain rule/branch behind the AT) and, where the AT crosses an I/O boundary, a thin **shell/integration test** (verifies the shell wires the right data into the core and persists/returns the result correctly).
- Don't just copy each AT verbatim to the component level — decompose it. One AT can require several component tests (e.g., a core rule test plus an integration test), and one component test may support multiple ATs; record both directions.
- Use a table per component (or one consolidated table for small designs):

  | Test ID | Component | Layer (core \| shell) | Verifies AT(s) | Given | When | Then |
  | --- | --- | --- | --- | --- | --- | --- |

- Prefix component test IDs distinctly from ATs, e.g. `ct-<slug>`, so they're never confused with the acceptance-test IDs they trace to.
- Cover every branch/edge case named in the functional core (Phase 9) even if no single AT calls it out explicitly — flag any such gap-filling test as design-driven rather than AT-driven so the distinction is visible.
- Skip generating component tests for trivial passthrough components with no branching logic (consistent with Phase 9's guidance not to force a core split where there's nothing to isolate).

## Phase 11: Traceability

Produce a single traceability matrix tying requirements all the way through to design and tests — gaps here (a requirement with no component, or a component with no test) are defects in the design pass, not acceptable omissions:

| Requirement / Use Case | Component(s) | Boundary Contract Item(s) | Schema Table(s) | ADR(s) | Diagram(s) | Component Test(s) |
| --- | --- | --- | --- | --- | --- | --- |

- One row per use case (or functional requirement, for cross-cutting NFR-driven rows); populate every column that applies — an empty column is a legitimate "not applicable," but an untraced use case (no component at all) must be called out as a gap, not left blank silently.
- Keep this matrix in sync whenever a design artifact changes — update it in the same edit, not as a follow-up.

## Phase 12: Draft the SDD (HTML)

Deliver the SDD as a single self-contained HTML file, not plain Markdown — this is what allows the Mermaid diagrams (Phase 7) to render directly when the file is opened, instead of staying as unrendered code blocks:

- Structure: a minimal `<style>` block for readable typography/tables, a table of contents linking to each section via anchors, and the sections below as `<h2>`/`<h3>` headings.
- Render diagrams with the Mermaid browser bundle: include `<script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.esm.min.js" type="module">` (or the equivalent current CDN URL) that calls `mermaid.initialize(...)`, and author each diagram as `<pre class="mermaid">...diagram source...</pre>`.
- Sections, in this order:
  1. **Introduction** — purpose, scope, links to the source SRS/requirements (or a summary of the problem if none exists), the kind of system being designed (Phase 1), and a link to the ADR directory.
  2. **Architecture Overview** — the chosen shape (single service / modules / services / client-only app / library), the component diagram, and why it's the simplest fit — reference the relevant ADR(s) rather than re-arguing them.
  3. **Tech Stack** — the Concern/Choice/ADR summary table from Phase 4, linking into the ADR directory for the reasoning behind each choice.
  4. **Diagrams** — the sequence diagram(s) and the deployment diagram (Phase 7), each with its caption. (The component diagram may live here instead of Architecture Overview if that reads better for the design in question — don't duplicate it in both places.)
  5. **Boundary Contracts** — prose summary of whichever boundary contract(s) apply (Phase 5: API, UI/component, CLI, library surface, events) and their purpose; link to the corresponding spec file(s) as the source of truth. State explicitly if a contract type doesn't apply to this system.
  6. **Data Boundary** — prose summary of the persistence model and ownership if the system owns persisted state (Phase 6); link to the schema file as the source of truth. If the system owns no persisted state, say so explicitly and note where persistence actually lives instead.
  7. **Internal Design** — component/module breakdown, each with its single responsibility, dependencies, and coupling notes (Phase 8); the functional-core/imperative-shell split for components with real logic (Phase 9).
  8. **Cross-Cutting Concerns** — auth, error handling/observability, and any other concern that spans components, only if relevant to the requirements in scope.
  9. **Decisions** — a table of ADRs (number, title, status) linking into the ADR directory; don't restate their content.
  10. **Component-Level Tests** — a summary/link to the component test doc (Phase 10); embed the table directly if it's small, otherwise link out.
  11. **Traceability** — the matrix from Phase 11, embedded as an HTML table so it's viewable without opening another file.
  12. **Open Questions / Future Considerations** — anything explicitly deferred, so it's clear it was considered and intentionally excluded from this design pass.
- Keep the HTML dependency-free beyond the single Mermaid CDN script — no build step should be required to view the document; opening the file in a browser must be sufficient.

## Delivering the Result

- Default file locations, unless the user specifies otherwise:
  - `docs/design/SDD.html` for the design document (self-contained HTML with embedded Mermaid diagrams)
  - `docs/design/adr/NNNN-<slug>.md` for each ADR (including tech stack decisions, Phase 4)
  - `docs/design/openapi.yaml` for an HTTP API spec, if the system has one (Phase 5) — substitute the appropriate contract file/format for other boundary kinds (e.g., a UI component contract doc, a CLI reference, a library's public API/type declarations), or omit entirely if no such contract applies
  - `docs/design/schema.sql` (or the appropriate format for the target datastore) for the database schema, only if the system owns persisted state (Phase 6) — omit if it doesn't
  - `docs/design/Component-Tests.md` for the component-level test plan (Phase 10)
- Confirm scope (Phase 1, including the kind of system) before producing artifacts if requirements are ambiguous or no SRS exists; don't silently invent scope or assume a backend service by default.
- After creating the documents, briefly summarize what was produced (ADR count/titles including the tech stack decisions, boundary contract(s) produced and their size, schema table count if applicable, diagram count, component-test count, and any traceability gaps found) rather than repeating full content back in chat.
- If a requirement forces added complexity (e.g., a second datastore, an async boundary), say so explicitly and point to the requirement/ADR that justifies it — never introduce complexity silently.
