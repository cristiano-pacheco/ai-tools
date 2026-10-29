# Client

Use `client/<name>_client.go` for a remote-service protocol consumed by application
policy. Put its consumer-owned interface in `port` and application values in
`dto`. A third-party business capability selects Provider even when its SDK
uses HTTP. The transport mechanism does not determine application ownership.

## Recipe: outbound protocol adapter

1. Inspect the pinned API/protocol, endpoints, authentication, timeout, limits,
   response/error shape, and idempotency contract. Keep all wire types private.
2. Inject the configured transport and typed settings. The concrete struct
   asserts its port; its constructor returns a concrete pointer, with error when
   configuration cannot be accepted.
3. Build requests with caller context, bound response reads, close bodies, and
   classify statuses before decoding success. Map the response into application
   values; a decoded but invalid protocol result is not application success.
4. Translate documented business outcomes to stable errors. Wrap unknown network/
   decode failures with cause preserved. Keep retries and business acceptance
   with the operation; do not silently repeat a side effect after a timeout.
5. Follow the project's I/O telemetry/logging owner and register the port through
   Fx only when consumed. Test with a controlled protocol server, not a mock that
   merely returns a DTO and bypasses the adapter.

## Example: quote contract

`internal/modules/order/dto/shipping_quote_dto.go`.

```go
package dto

type ShippingQuoteInput struct{ PostalCode string }
type ShippingQuote struct {
	AmountCents int64
	Currency    string
}
```

`internal/modules/order/port/shipping_client.go`.

```go
package port

import (
	"context"

	"example.com/project/internal/modules/order/dto"
)

type ShippingClient interface {
	Quote(ctx context.Context, input dto.ShippingQuoteInput) (dto.ShippingQuote, error)
}
```

## Example: bounded HTTP client

`internal/modules/order/client/shipping_client.go`. The example protocol is
`GET /quotes/{postalCode}` returning JSON `amount_cents`/`currency`. Adapt the
real protocol; the process supplies a transport with a bounded timeout.

```go
package client

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"example.com/project/internal/modules/order/dto"
	"example.com/project/internal/modules/order/errs"
	"example.com/project/internal/modules/order/port"
	"github.com/cristiano-pacheco/bricks/pkg/otel/trace"
)

const maxQuoteBodyBytes = 1 << 20

type shippingQuoteResponse struct {
	AmountCents int64  `json:"amount_cents"`
	Currency    string `json:"currency"`
}

type ShippingClient struct {
	baseURL    string
	httpClient *http.Client
}

var _ port.ShippingClient = (*ShippingClient)(nil)

func NewShippingClient(baseURL string, httpClient *http.Client) (*ShippingClient, error) {
	parsed, err := url.Parse(baseURL)
	if err != nil {
		return nil, fmt.Errorf("parse shipping URL: %w", err)
	}
	if (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" || parsed.RawQuery != "" || parsed.Fragment != "" {
		return nil, fmt.Errorf("invalid shipping base URL")
	}
	return &ShippingClient{baseURL: strings.TrimRight(parsed.String(), "/"), httpClient: httpClient}, nil
}

func (c *ShippingClient) Quote(ctx context.Context, input dto.ShippingQuoteInput) (dto.ShippingQuote, error) {
	ctx, span := trace.Span(ctx, "ShippingClient.Quote")
	defer span.End()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/quotes/"+url.PathEscape(input.PostalCode), nil)
	if err != nil {
		return dto.ShippingQuote{}, fmt.Errorf("build shipping quote: %w", err)
	}
	response, err := c.httpClient.Do(req)
	if err != nil {
		return dto.ShippingQuote{}, fmt.Errorf("fetch shipping quote: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return dto.ShippingQuote{}, fmt.Errorf("%w: shipping status %d", errs.ErrDependencyUnavailable, response.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, maxQuoteBodyBytes+1))
	if err != nil {
		return dto.ShippingQuote{}, fmt.Errorf("read shipping quote: %w", err)
	}
	if len(body) > maxQuoteBodyBytes {
		return dto.ShippingQuote{}, fmt.Errorf("%w: oversized shipping response", errs.ErrDependencyUnavailable)
	}
	var payload shippingQuoteResponse
	if err := json.Unmarshal(body, &payload); err != nil {
		return dto.ShippingQuote{}, fmt.Errorf("decode shipping quote: %w", err)
	}
	if payload.AmountCents < 0 || payload.Currency == "" {
		return dto.ShippingQuote{}, fmt.Errorf("%w: invalid shipping response", errs.ErrDependencyUnavailable)
	}
	return dto.ShippingQuote{AmountCents: payload.AmountCents, Currency: payload.Currency}, nil
}
```

*Check:* request/auth mapping, cancellation, timeout, status classification,
bounded/malformed/invalid payloads, closed bodies, and stable application output.
Use a controlled server to prove the actual protocol behavior. An upstream 200
alone does not establish a valid business result or safe retry.

## Example: controlled protocol proof

`internal/modules/order/client/shipping_client_test.go`. This checks real HTTP
mapping/classification and cancellation without contacting an external service.

```go
package client_test

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"example.com/project/internal/modules/order/client"
	"example.com/project/internal/modules/order/dto"
	"example.com/project/internal/modules/order/errs"
)

func TestShippingClient(t *testing.T) {
	t.Run("valid response", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method != "GET" || r.URL.Path != "/quotes/00000-000" {
				t.Errorf("unexpected request: %s %s", r.Method, r.URL.Path)
			}
			_, _ = w.Write([]byte(`{"amount_cents":1250,"currency":"BRL"}`))
		}))
		defer server.Close()
		adapter, err := client.NewShippingClient(server.URL, server.Client())
		if err != nil {
			t.Fatal(err)
		}
		value, err := adapter.Quote(context.Background(), dto.ShippingQuoteInput{PostalCode: "00000-000"})
		if err != nil || value.AmountCents != 1250 || value.Currency != "BRL" {
			t.Fatalf("got %#v, %v", value, err)
		}
	})
	t.Run("oversized response is dependency failure", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			_, _ = w.Write([]byte(strings.Repeat("x", (1<<20)+1)))
		}))
		defer server.Close()
		adapter, err := client.NewShippingClient(server.URL, server.Client())
		if err != nil {
			t.Fatal(err)
		}
		_, err = adapter.Quote(context.Background(), dto.ShippingQuoteInput{PostalCode: "00000-000"})
		if !errors.Is(err, errs.ErrDependencyUnavailable) {
			t.Fatalf("unexpected oversized outcome: %v", err)
		}
	})
	t.Run("caller cancellation", func(t *testing.T) {
		adapter, err := client.NewShippingClient("http://127.0.0.1:1", http.DefaultClient)
		if err != nil {
			t.Fatal(err)
		}
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		_, err = adapter.Quote(ctx, dto.ShippingQuoteInput{PostalCode: "00000-000"})
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("lost cancellation: %v", err)
		}
	})
}
```
