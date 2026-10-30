# Configuration

Read for source precedence, typed settings, defaults/validation, environment
substitution or config/Fx bindings. Use Bricks `pkg/config` as the loader.

## Load contract

`config/base.yaml` is required. `APP_CONFIG_DIR` selects the directory (default
`config`, relative to process working directory); `APP_ENV` selects an optional
lowercased environment overlay (default `local`). Load base then overlay.
`config.New[T](config.WithPath("app.order"))` returns a concrete `config.Config[T]`;
`Get()` returns the decoded value. `config.Provide[T]("app.order")` registers it.
Use `config` field tags, not inferred tags from another loader.

A string `env://NAME` resolves with `os.Getenv`. Missing variables become empty
strings rather than loader errors; required secrets need explicit startup
validation. Resolution happens while each file loads, before the overlay merges:
a missing base variable can still fail numeric conversion if not overridden.
List required variable names with blank values in `.env.example`; values stay
external to committed configuration. There are no automatic key-derived environment overrides. Document any deliberate
flag override precedence at the command owner.

## Example: owned module settings

`internal/modules/order/config/config.go`. A validated concrete value is supplied
to its consumers; primitive settings do not travel through unrelated constructors.

```go
package config

import (
	"fmt"

	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
)

type Config struct {
	ExportMaxItems int `config:"export_max_items"`
}

func NewConfig(loaded bricksconfig.Config[Config]) (Config, error) {
	value := loaded.Get()
	if value.ExportMaxItems < 1 || value.ExportMaxItems > 10000 {
		return Config{}, fmt.Errorf("order export_max_items must be between 1 and 10000")
	}
	return value, nil
}
```

`internal/modules/order/config_fx.go`. Include this option in the owner `Module`
when an actual component consumes the settings; a YAML section alone does not
justify a new application package/provider.

```go
package order

import (
	moduleconfig "example.com/project/internal/modules/order/config"
	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
	"go.uber.org/fx"
)

var ConfigModule = fx.Module("order-config",
	bricksconfig.Provide[moduleconfig.Config]("app.order"),
	fx.Provide(moduleconfig.NewConfig),
)
```

YAML matches the owned tags; base declares the safe shape, overlays only changes:

```yaml
app:
  order:
    export_max_items: 1000
```

## Example: prove the real loader

`internal/modules/order/config/config_test.go`. This test exercises base, overlay,
tags and concrete validation, independently of database/server initialization.
Use `t.Setenv` only in nonparallel tests because it changes process environment.

```go
package config_test

import (
	"os"
	"path/filepath"
	"testing"

	moduleconfig "example.com/project/internal/modules/order/config"
	bricksconfig "github.com/cristiano-pacheco/bricks/pkg/config"
)

func TestConfigurationOverlay(t *testing.T) {
	directory := t.TempDir()
	for name, body := range map[string]string{
		"base.yaml": "app:\n  order:\n    export_max_items: 1000\n",
		"test.yaml": "app:\n  order:\n    export_max_items: env://ORDER_EXPORT_MAX_ITEMS\n",
	} {
		if err := os.WriteFile(filepath.Join(directory, name), []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
	}
	t.Setenv("APP_CONFIG_DIR", directory)
	t.Setenv("APP_ENV", "test")
	t.Setenv("ORDER_EXPORT_MAX_ITEMS", "25")
	loaded, err := bricksconfig.New[moduleconfig.Config](bricksconfig.WithPath("app.order"))
	if err != nil {
		t.Fatal(err)
	}
	value, err := moduleconfig.NewConfig(loaded)
	if err != nil || value.ExportMaxItems != 25 {
		t.Fatalf("got %#v, %v", value, err)
	}
}
```

Platform subtree names are fixed by their modules: `app.logger`, `app.http`,
`app.open-telemetry`, `app.i18n`, and `app.redis` when those modules are consumed.
`app.ucdecorator` belongs only to the explicitly requested decorator branch or
an existing decorated use case being modified; omit it from the default direct
stack. Database loading belongs to the application's shared database module.
[Server](server.md) supplies a compatible complete base for the example stack.

*Check:* exact subtree/tags, base/overlay/env behavior through the real loader,
validated required values and bounds, one provider per concrete config type,
and no credentials in code, fixtures or diagnostics.
