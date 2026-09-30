# LuaSmith 4 — Collision Battlestar Engineering Agent Specification

Date: 2026-09-30
Status: Proposed for implementation after owner review
Branch: feature/luasmith-engineering-agent-20260930

## 1. Objective

Transform LuaSmith from a small offline/online Lua/Luau code generator into a repository-aware engineering agent for Collision Battlestar.

The agent must be able to research relevant references, understand the real repository, propose and implement bounded changes, execute validation, maintain a private Roblox test place when configured, create auditable pull requests, and support a controlled recurring maintenance cycle.

LuaSmith must improve the game through verified engineering. It cannot guarantee a particular player count, retention level, revenue level, or absence of every production defect. It must instead make failures observable, block unsafe releases, and continuously reduce known regression risk.

## 2. Existing constraints and defects

The current package declares ESM mode while luasmith-v3.js uses CommonJS require(), creating a startup incompatibility.

The current embedded knowledge base contains only six patterns. It is not an adequate reference system for a production Roblox project.

The current agent validates the repository and can build with Rojo, but it does not have a first-class Roblox test-place pipeline.

The current repair agent can apply up to eight complete-file operations from an LLM response. Its mutation safety is useful but its semantic verification is too shallow for autonomous production maintenance.

Collision Battlestar already has Rojo, GitHub Actions, Luau tests, source validation and an Open Cloud publication workflow. The LuaSmith design must extend these systems rather than replace them.

## 3. Design principles

1. Evidence before mutation.
2. Repository truth before model memory.
3. Server authority for all protected gameplay state.
4. Test before merge.
5. Test place before production.
6. Production publication is a separate protected gate.
7. AI may propose or implement changes but cannot invent project facts.
8. Every automatic change is auditable and reversible.
9. Research results are stored with provenance.
10. The system must fail closed when evidence is insufficient.
11. Mobile performance is a release criterion.
12. No autonomous monetization experiments without an explicit configuration and owner-controlled permissions.

## 4. System architecture

LuaSmith is divided into these modules:

- CLI
- Web UI
- Provider Router
- Reference Engine
- Repository Index
- Project Contract Store
- Planner
- Code Transformer
- Validator
- Roblox Test Runner
- Change Auditor
- GitHub Integration
- Release Controller
- Maintenance Scheduler

Data flow:

request
-> intent classification
-> repository snapshot
-> reference retrieval
-> impact analysis
-> implementation plan
-> isolated change
-> static/unit validation
-> Roblox test-place validation
-> audit
-> pull request
-> protected release gate
-> production publish

## 5. Provider Router

Supported providers:

- Local embeddings
- Ollama
- Hugging Face
- OpenAI
- Google/Gemini where configured by the owner
- Deterministic offline fallback

The router must not infer provider capabilities. Each provider implements an explicit interface.

The provider layer must enforce:
- request timeout
- maximum response size
- structured output validation
- retry policy
- provider fallback
- model metadata recording

API keys must only exist in environment variables or external secret stores.

## 6. Reference Engine

Replace the six-entry KB with a provenance-aware reference index.

Each reference record contains:

- reference_id
- source_type
- title
- canonical_url
- retrieved_at
- content_hash
- topic_tags
- api_symbols
- project_relevance
- content
- license_or_usage_note when known

Source classes:

- Roblox Creator Hub
- Roblox Open Cloud documentation
- Roblox API/reference pages
- official GitHub repositories
- selected public Roblox/Luau projects
- Collision Battlestar documentation
- Collision Battlestar tests
- accepted engineering decisions
- known regressions and fixes

The reference engine supports:
- semantic search
- exact symbol search
- API-name search
- repository-symbol search
- multi-source answer synthesis
- stale-reference detection

The system must prioritize first-party Roblox documentation for Roblox API behavior, then project-local evidence, then carefully selected public examples.

References must never be copied into executable game code automatically merely because they appear in search results.

## 7. Repository Index

The repository index tracks:

- files
- modules
- requires
- RemoteEvents/RemoteFunctions
- attributes
- exported interfaces
- services
- test modules
- workflows
- Rojo mappings
- game IDs
- configuration contracts

It must construct an impact graph:

file -> imports -> callers -> remotes -> state -> tests

Before changing a file, the agent records the affected graph region.

## 8. Project contract

Create a machine-readable project contract containing:

- experience identity
- universe/place identifiers
- allowed production paths
- test-place identifiers when configured
- server/client ownership rules
- protected modules
- required validation commands
- release policy
- owner/admin identity configuration
- performance budgets
- maximum autonomous operations
- required approvals

Secrets are never stored inside the project contract.

## 9. Safe code operations

The model may return only typed operations:

- create_file
- update_file
- create_test
- update_test
- update_docs

No delete operation is available to the autonomous repair agent.

Every operation must include:

- path
- complete content
- reason
- expected behavior
- validation target

Path allowlists remain mandatory.

A change that modifies a protected file requires a higher release tier.

## 10. Mandatory verification ladder

### Gate 1: Syntax/static
- Luau compilation where available
- Python validation
- YAML/JSON validation
- git diff --check

### Gate 2: Unit
- all shared rule tests
- all regression tests

### Gate 3: Build
- Rojo build
- resulting RBXL is non-empty

### Gate 4: Repository audit
- no merge markers
- no loadstring
- no unauthorized path
- no duplicate runtime system
- no missing required file
- no unresolved required require target

### Gate 5: Roblox test place
When configured, publish the candidate build to the dedicated test place and execute automated Luau tests through the supported Open Cloud execution flow.

The production place must never be the test target.

### Gate 6: Release audit
- change summary
- affected systems
- tests passed
- test-place result
- performance result when available
- rollback reference

A failed gate blocks promotion.

## 11. Private Test Lab

Collision Battlestar receives an owner-only Test Lab.

Authorization is server-side by configured trusted UserId values.

The lab exposes controlled test actions such as:

- start wave
- spawn elite
- spawn selected enemy tier
- reset wave
- reset player
- grant test credits
- equip test loadout
- summon Friend Echo
- open shop test state
- run combat validation
- run AI validation
- inspect runtime counters

Test actions are disabled in public production servers unless an explicit owner-only safe-mode configuration enables them.

No test action is client-authoritative.

The lab reports:

- current wave
- active enemies
- elite state
- active companions
- server heartbeat
- remote action rate
- validation failures
- runtime warnings
- memory/performance counters that are available through supported Roblox APIs

## 12. Autonomous maintenance

Recurring maintenance must be scheduled outside the live game server.

Maintenance flow:

schedule
-> collect current repository state
-> collect permitted external references
-> inspect open issues and recent failures
-> identify candidate improvements
-> create isolated branch
-> implement small change
-> run full validation
-> run test-place validation
-> open pull request
-> stop at protected merge gate

Production deployment must never be a hidden side effect of research or maintenance.

## 13. Update cadence

The system should support configurable cadences:

- daily: health/research scan
- weekly: dependency/API/reference audit
- biweekly: small maintenance batch
- monthly: feature/retention/performance review
- release events: explicit owner-controlled deployment

The scheduler must create no-op reports when there is no justified change. It must not manufacture updates merely to keep the repository active.

## 14. Game quality feedback loop

LuaSmith integrates engineering signals with permitted game analytics.

Core signals:

- first-session completion
- first-kill completion
- first-wave completion
- elite encounter completion
- first upgrade
- average session time
- D1/D7/D30 retention when available
- error/crash indicators
- mobile performance indicators
- shop interaction funnel
- companion adoption
- return-player engagement

The system uses these as diagnostic inputs, not automatic proof that a design is successful.

When analytics indicate a regression, LuaSmith creates a reproducible investigation task before attempting a code change.

## 15. Experiment support

The architecture allows controlled configuration/experiment definitions.

Experiments must have:

- experiment_id
- hypothesis
- eligible population
- variables
- success metrics
- stop conditions
- start/end time
- owner

The agent can analyze results and prepare a recommendation, but production rollout remains protected by the release policy.

## 16. Roblox-specific safety

The agent must enforce:

- server-owned damage
- server-owned rewards
- server-owned prices
- server-owned ownership
- server-owned admin authorization
- server-side range and cooldown checks
- server-side target validation
- no client-supplied privileged state
- safe DataStore retry behavior
- idempotent developer-product receipt handling
- bounded AI loops
- bounded overlap queries
- explicit pathfinding recovery
- mobile-safe HUD layouts

Roblox API claims must be verified against current official documentation before being encoded as new rules.

## 17. GitHub integration

LuaSmith may:

- create branches
- create/update files
- create tests
- create pull requests
- add verification reports
- comment on pull requests
- inspect workflow results

It must not silently rewrite the production branch.

The PR body must contain:

- objective
- changed systems
- reference set
- tests
- build
- test-place status
- known limitations
- rollback commit

## 18. Release controller

Production publishing is a distinct subsystem.

Required conditions:

1. branch status is eligible
2. validation workflow passes
3. test-place verification passes when configured
4. release audit passes
5. protected publication condition is satisfied

The existing Collision Battlestar main-branch publisher must be hardened so that development/test branches cannot publish to the production place.

## 19. Observability and audit log

Each agent run creates an audit record:

- run_id
- timestamp
- request
- model/provider
- references used
- repository base SHA
- changed paths
- validation results
- test-place result
- PR number
- final decision

Logs must exclude secrets and sensitive user data.

## 20. Failure handling

Failures are classified:

- INPUT
- REFERENCE
- MODEL
- CODE
- TEST
- BUILD
- ROBLOX_RUNTIME
- PROVIDER
- PERMISSION
- RELEASE

For each failure the agent records:
- phase
- exact failing command or API
- affected artifact
- likely root cause
- whether retry is safe

Retries are bounded and only automatic for explicitly retryable failures.

## 21. Performance budgets

The Collision Battlestar profile should preserve the current bounded PvE architecture.

Initial budgets:

- maximum active wave enemies: 20
- maximum active Echoes per player: 1
- bounded AI update frequency
- bounded path recomputation
- bounded combat FX
- no uncontrolled per-frame server polling
- no unnecessary high-frequency gameplay remotes

The exact thresholds remain configurable in the project contract.

## 22. Security model

Three trust levels:

### Level 0 — Read
Repository/reference inspection only.

### Level 1 — Development mutation
Changes isolated branches and test artifacts.

### Level 2 — Release
May open release candidates and invoke production publication only when all release gates are satisfied.

No model response can escalate its own trust level.

## 23. Deliverables

The implementation must produce:

- repaired LuaSmith runtime
- reference/indexing subsystem
- provider abstraction
- repository analyzer
- test-place runner integration
- audit log
- maintenance scheduler
- Collision Battlestar Test Lab
- strengthened CI validation
- protected release workflow
- documentation and operator commands
- regression tests

## 24. Success criteria

LuaSmith is considered ready when:

1. it starts correctly under the declared Node module system;
2. offline search works;
3. at least one configured online provider works;
4. provider failure falls back safely;
5. project context is indexed;
6. references carry provenance;
7. generated changes are constrained by path and operation policy;
8. every mutation is followed by validation;
9. the repository can be built by Rojo;
10. the Test Lab is owner-authorized and server-controlled;
11. test-place verification can run when configured;
12. production publication is isolated from development;
13. automated maintenance produces auditable pull requests rather than silent production edits;
14. the system records enough evidence to reproduce why a change was accepted or rejected.

## 25. External references used for this design

Roblox Creator Hub — Analytics:
https://create.roblox.com/docs/production/analytics

Roblox Creator Hub — Performance optimization:
https://create.roblox.com/docs/performance-optimization

Roblox Creator Hub — Analytics API:
https://create.roblox.com/docs/pt-br/cloud/guides/analytics

Roblox Creator Hub — Data Stores:
https://create.roblox.com/docs/cloud-services/data-stores

Roblox Creator Hub — PathfindingService:
https://create.roblox.com/docs/reference/engine/classes/PathfindingService/CreatePath

Roblox official GitHub — Place CI/CD demo:
https://github.com/Roblox/place-ci-cd-demo

The official Roblox CI/CD example demonstrates a separate test place plus Rojo, lint/format validation, Open Cloud Luau execution and deployment. It explicitly warns that the sample is not battle tested, so LuaSmith will treat it as a reference architecture rather than copy it uncritically.

## 26. Explicit non-goals

LuaSmith must not:

- guarantee thousands of concurrent players;
- auto-copy arbitrary public game code;
- use exploits or client-authority shortcuts;
- invent Roblox API behavior;
- silently change production economy values;
- silently publish unreviewed feature changes;
- collect secrets into the reference database;
- manufacture meaningless updates.
