# Provider

A provider adapts a third-party capability such as email, payment, signing, or
identity. Name the port for the needed capability, not the vendor. Put the port
in the consumer module, SDK implementation in `provider`, and shared application
input/output in `dto`. An HTTP-based vendor is still a provider; Client owns a
remote-service protocol when that is the actual responsibility.

## Recipe: SDK capability

1. Read the pinned SDK's constructor, request/result types, error classification,
   context support, timeout, delivery confirmation, and retry semantics. Verify
   methods from its installed source/official API before writing calls.
2. Keep concrete SDK/client fields inside the adapter. Add the compile-time
   application-port assertion and a constructor returning `*<Name>Provider`,
   optionally with error. Constructor success does not imply successful delivery.
3. Map application values into SDK request values at this boundary. Forward caller
   context where the API supports it; configure bounded calls through the SDK's
   documented mechanism when it does not. Keep wire/SDK values out of the port.
4. Map only documented provider rejections with application meaning to stable
   module errors. Preserve unknown causes. Do not conflate rejection, transient
   dependency failure, and an unknown result after a timeout.
5. Keep operation-level retry/idempotency policy with the application contract;
   configure SDK retries consistently so nested retries do not multiply attempts.
   Use a stable identity for protected side effects. Database rollback cannot
   undo a completed provider call; select Consistency for outbox/compensation needs.
6. Publish the concrete instance through Fx at its owner. Apply established I/O
   telemetry and log at the project's chosen failure boundary, preserving secrets.

## Example contract to adapt

[Service](service.md#example-service-input-and-provider-value) defines
`port.EmailProvider.Send(ctx, dto.EmailMessage) error` and a service consuming
it. A real provider implements that application contract, mapping its fields to
the inspected SDK. Implementing `Send` must use the real pinned API, not invented
`receiptapi`/`mailapi` helpers. [Client](client.md) supplies a complete HTTP
mechanics example when the selected provider protocol itself is HTTP; reuse the
mechanics without changing the provider's responsibility.

## Verification

Use the SDK's supported sandbox/fake transport or a controlled protocol server
for request/auth mapping, success result, documented rejection, wrapped unknown
failure, cancellation, and uncertain timeout. In a wider application integration
flow, replace an uncontrolled external system at this port when the project
permits it. Controlled local DB/cache dependencies remain real.

*Check:* pinned APIs, no SDK leak, concrete constructor/assertion/Fx
agreement, bounded contextual calls, defined delivery/idempotency meaning, and
observable proof of both accepted and failed outcomes.
