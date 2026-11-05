# Request decoding

Read when changing HTTP body syntax, content types, size limits, or decode errors. Keep application field validation in the use case.

1. Decode into an HTTP-owned request DTO. Define whether the endpoint requires an object, accepts `null`, rejects unknown fields, and requires a particular content type.
2. Set the endpoint's read bound. Decide whether the contract requires consuming the entire body and rejecting trailing data. Do not infer whole-body validation from a successful first decode.
3. Reject malformed input before invoking the operation. Preserve distinct unsupported-media and body-too-large outcomes rather than replacing every error with a generic 400.
4. For Bricks parser APIs and their actual guarantees, follow [Bricks handoff](bricks.md) to `references/http/request/usage.md`. Apply any stricter project policy at the shared HTTP boundary.
5. Verify changed transport behavior through API end-to-end coverage under [Test policy](test-policy.md). An application integration request does not authorize a separate parser test suite.

Done when malformed input cannot invoke the operation, object and limit policies are explicit, and parser errors reach the compatible [response boundary](response.md). [HTTP body](http-body.md) shows the application sequence.
