# AI Tools Engineering Workflow

The vocabulary of the agent-driven workflow that turns a conversation into a spec, tickets, and implemented code.

## Language

### Planning

**Spec**:
The agreed description of a feature, published to the tracker before it is split into tickets.
_Avoid_: PRD, plan, design doc

**Ticket**:
One small, independently verifiable unit of work derived from a spec, with acceptance criteria and blocking edges.
_Avoid_: Issue, task, story

**Blocking edge**:
A declared dependency meaning one ticket cannot start until another is resolved.
_Avoid_: Dependency, prerequisite, blocker

**Frontier**:
The set of tickets that are ready for an agent and whose blocking edges all point to resolved tickets.
_Avoid_: Queue, backlog, next tickets

### Ticket status

**ready-for-agent**:
A ticket fully specified for an agent to implement without a person.

**claimed**:
A ticket an agent is currently implementing.
_Avoid_: In progress, started

**needs-human**:
A claimed ticket an agent stopped on because only a person can clear the obstacle; it returns to ready-for-agent once cleared.
_Avoid_: Blocked, stuck, failed

**ready-for-human**:
A ticket decided at triage to be implemented by a person, never picked by an agent.

**resolved**:
A ticket whose acceptance criteria are met, reviewed, and committed.
_Avoid_: Done, closed, complete

### Execution

**Integration branch**:
The single branch where every resolved ticket of one spec is merged.
_Avoid_: Feature branch, main branch

**Orchestrator**:
The agent that works the frontier of one spec, dispatching implementers and merging their work into the integration branch.
_Avoid_: Runner, coordinator, manager

**Implementer**:
A fresh-context agent that implements exactly one ticket in its own worktree.
_Avoid_: Worker, executor
