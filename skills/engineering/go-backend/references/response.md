# HTTP response

Read when changing status, headers, success envelopes, error rendering, or response-write handling. Preserve the API's published format.

1. Map application Output into an HTTP-owned response DTO. Keep its JSON names and envelope separate from application values. Avoid wrapping a result twice.
2. Choose the published status and headers. Retrieval commonly uses 200, creation 201, and bodyless success 204. Preserve established action semantics and promised Location headers.
3. Render each outcome once through the application's shared response boundary. Known errors expose only safe codes, messages, and details. Unknown failures return a generic internal error without driver or SDK text.
4. Stop after a write failure. Headers may already be committed. Report it at the existing logging owner rather than rendering another body or invoking the operation again.
5. For Bricks response functions, error classification, validator details, and dependencies, follow [Bricks handoff](bricks.md) to `references/http/response/usage.md`. Do not assume installing a renderer logs every returned application error.
6. Apply [Test policy](test-policy.md). Verify changed status, headers, body, and error safety through the actual API end-to-end boundary.

Done when each request produces one compatible response, unexpected technical details stay private, and the reporting owner handles terminal write failures. [Error](error.md) owns application identity and causes.
