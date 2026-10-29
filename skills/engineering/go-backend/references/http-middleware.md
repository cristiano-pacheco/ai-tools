# HTTP middleware

Use module `http/chi/middleware` for a transport concern owned by that module;
shared technical middleware stays in shared infrastructure. Middleware can
establish trusted request context or enforce scoped transport mechanics. It
contains no use-case orchestration, repository/provider call, or business rule.

A dependency-free enrichment can be a package function. Stateful middleware has
a concrete-pointer constructor, explicit dependencies, and Fx registration.
If it can reject, reuse the established error renderer rather than inventing an
envelope. Apply it through the router's smallest affected group; order is part
of the contract and must be tested when it changes.

## Example: scoped context enrichment

`internal/modules/order/http/chi/middleware/preview_middleware.go`. A caller
header only requests presentation preview; it does not establish trusted actor,
tenant, role, or authorization state.

```go
package middleware

import (
	"context"
	"net/http"
	"strings"
)

type previewKey struct{}

func Preview(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requested := strings.EqualFold(strings.TrimSpace(r.Header.Get("X-Preview")), "true")
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), previewKey{}, requested)))
	})
}

func IsPreview(ctx context.Context) bool {
	value, _ := ctx.Value(previewKey{}).(bool)
	return value
}
```

*Check:* typed private context key, preserved caller context/cancellation,
correct group/order, rejection rendering if applicable, and no unrelated route
impact. A pure enrichment needs no port, constructor, logger, or Fx binding.
