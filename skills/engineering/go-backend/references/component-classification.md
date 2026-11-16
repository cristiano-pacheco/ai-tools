# Component classification

Before creating or reclassifying a component, identify its owner, callers,
inputs/outputs, effects, and responsibility in one sentence. Choose the role by
that behavior before choosing a name, package, interface, constructor, or Fx
registration. Inspect project contracts first; neighboring names are not proof
of responsibility.

## Decision order

1. **Business entrypoint:** choose Usecase for a public application operation.
   Keep its operation-local orchestration there, even with one collaborator.
2. **Data or boundary:** distinguish passive representations, transport, and
   composition from application behavior using the table below.
3. **Collaborator:** classify its actual contract and implementation, including
   private helpers. Acceptance is Validator even with I/O; conversion of supplied
   values is Mapper. Separate independent responsibilities instead of choosing a
   broad suffix to cover them all.
4. **Reusable capability:** choose Service only for a focused capability not
   covered by the more specific roles. Reuse alone is insufficient; a helper
   private to one component stays with its owner.
5. **Unmatched or unresolved:** follow the decision gate below before creating
   files. Completion requires a justified role, not merely a plausible name.

## Role map

| Role | Responsibility and distinguishing evidence |
| --- | --- |
| Usecase | Public business operation: owns policy, collaborator sequence, atomicity decisions, and explicit application Input/Output. The transport calls this entrypoint, not its collaborators. |
| Service | Focused reusable application capability, such as password hashing or local random code generation. Not the public workflow, pure representation conversion, acceptance, or an I/O adapter. |
| Validator | Accepts/rejects an input or business condition; may load external evidence. Does not own the operation's workflow or mutations. |
| Mapper | Converts supplied representations, parses/formats values, or assembles DTOs without loading state or performing business effects. |
| Model | Passive persistence record, projection, or query criteria. Not a business workflow or an arbitrary API payload. |
| DTO | Passive application or transport-owned input/output value. Keep boundary ownership separate even when fields match. |
| Enum | Constrained named value with its accepted values and value-level invariants. |
| Repository | Persistence queries/writes and storage error adaptation. Not business policy. |
| Cache | Key/value caching, serialization, TTL, hit/miss/failure and invalidation mechanics. The operation owns fallback policy. |
| Client | Remote-service protocol mechanics are the contract being adapted. |
| Provider | Adapts a third-party capability, for example email delivery, payment, signing, or identity, behind application values. SDK/vendor translation is concrete evidence; the use of HTTP alone does not make it a Client. |
| Handler / Command | HTTP/Cobra transport entrypoint: decode, map, call one public usecase operation, render. Infrastructure commands need no artificial business usecase. |
| Router / Middleware | Route registration or transport-wide interception, not business orchestration. |
| Error | Stable failure identity/classification or a specialized error value. |
| Port | Consumer-owned contract for a collaborator; retains that collaborator's semantic role. Not an implementation role or a reason to invent a Provider. |
| Composition / Infrastructure | Wiring, configuration, database connections, migrations, lifecycle or resource ownership; use the corresponding recipe and Naming's explicit exceptions. |

Read the selected component recipe through [Routing](routing.md) and then apply
[Naming](naming.md). The role map selects responsibility; recipes define its
implementation contract.

## Usecase is the application entrypoint

Transport entrypoints (HTTP handlers, Cobra commands, or other application
transports) invoke the public usecase operation. The usecase orchestrates its
repositories, validators, services, clients/providers and caches as required.
Transport does not bypass it to call those collaborators directly. A simple
operation still has a usecase; a complex one does not become a Service merely
because it orchestrates many dependencies. Keep local workflow in that usecase;
extract only independently justified capabilities, not a second workflow layer.

## Provider is not a synonym for dependency

A constructor, an interface implementation, an Fx provider function, a stateless
struct, or something that “provides” a result does not establish the Provider
role. Fx's term describes construction/wiring, not architectural responsibility.

For code generation, inspect the behavior:

- Local random/security-code generation reused by flows: `CodeGeneratorService`.
- Formatting supplied data into a code representation: Mapper.
- An operation that authorizes issuance, generates, stores and returns a code:
  Usecase, delegating generation if a separate capability is justified.
- Adapting an external code-issuance vendor: Provider; a protocol-focused
  remote-service adapter instead follows Client.

Preserve explicit infrastructure contracts such as the transaction-scoped
`TransactionProvider` in [Consistency](consistency.md). This is a documented
resource/transaction boundary, not permission to call local computation Provider.

## Decision gate for unknown roles

First inspect the requested behavior, existing contracts, and the role map.
If no predefined role fits, or evidence cannot resolve competing roles, pause
creation of that component and ask the user. Do not silently invent a role or
force it into Service or Provider.

Before asking which type to create, present **2–3 concrete options** with:

- Proposed role/name and its responsibility boundary.
- Why it could fit, what evidence or trade-off distinguishes it, and any change
  to the requested scope needed to make it fit.
- A recommended option with a short rationale.

Options may reuse an existing owner, split distinct responsibilities, or propose
an explicitly named new role. Do not fabricate a matching predefined role.
Ask the user to choose or specify a different boundary; a structured question
should carry these options when the harness supports it. Proceed only after
agreement on responsibility, role, and suffix. Record an approved new role in
the project's architectural/naming contract, not just in the generated filename.

*Check:* every new/reclassified component has evidence for its role, transport
reaches business behavior through Usecase, Provider has an adaptation or explicit
infrastructure contract, and unresolved roles have user approval before creation.
