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

**Project**:
A repository that implements tickets; each ticket belongs to one project, and a spec may span several.
_Avoid_: Repo, service, codebase

**Blocking edge**:
A declared dependency meaning one ticket cannot start until another is resolved.
_Avoid_: Dependency, prerequisite, blocker

**Frontier**:
The set of unclaimed ready-for-agent tickets whose blocking edges all point to resolved tickets.
_Avoid_: Queue, backlog, next tickets

### Ticket status

**ready-for-agent**:
A ticket fully specified for an agent to implement without a person.

**claimed**:
A ticket one agent holds and is working on; no other agent may take it.
_Avoid_: In progress, started, assigned

**needs-human**:
A ticket an agent stopped on because only a person can clear the obstacle; it returns to ready-for-agent once cleared.
_Avoid_: Blocked, stuck, failed

**ready-for-human**:
A ticket decided at triage to be implemented by a person, never picked by an agent.

**resolved**:
A ticket whose acceptance criteria are met, whose review has no unresolved findings, and whose work is committed.
_Avoid_: Done, closed, complete

**wontfix**:
A ticket a person decided will not be done, at triage or after acceptance.
_Avoid_: Cancelled, abandoned, deleted

### Execution

**Integration branch**:
The single branch where every resolved ticket of one spec is merged.
_Avoid_: Feature branch, main branch

**Orchestrator**:
The agent that works the frontier of one spec, dispatching implementers and merging their work into the integration branch.
_Avoid_: Runner, coordinator, manager

**Implementer**:
A fresh-context agent that implements exactly one ticket, or fixes its review findings, in its own worktree.
_Avoid_: Worker, executor

**Reviewer**:
A fresh-context agent, never the ticket's implementer, that reviews one ticket's committed work and either resolves it or records findings.
_Avoid_: Checker, verifier

**Review round**:
One review of a ticket; a ticket that still has findings after its second round needs a human.
_Avoid_: Iteration, pass
