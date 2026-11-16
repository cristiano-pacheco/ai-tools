# Configuration

Read when changing settings ownership, defaults, validation, or source precedence. Framework loader APIs belong to the [Bricks handoff](bricks.md), which selects `references/config/usage.md` in the Bricks skill.

## 1. Assign an owner

Keep typed settings with the module or shared resource that consumes them. Add a configuration package only when behavior needs it. Pass one validated concrete value to its consumers rather than unrelated primitive settings through several constructors.

## 2. Define the contract

Document required values, bounds, safe defaults, and source precedence. Keep secrets external and list required variable names with blank values in `.env.example`. Do not assume a loader applies defaults, calls validation, or rejects missing environment variables. Verify those mechanisms through the selected framework guide.

## 3. Validate before publication

`internal/modules/order/config/config.go`:

```go
package config

import "fmt"

type Config struct {
    ExportMaxItems int `config:"export_max_items"`
}

func NewConfig(value Config) (Config, error) {
    if value.ExportMaxItems < 1 || value.ExportMaxItems > 10000 {
        return Config{}, fmt.Errorf("order export_max_items must be between 1 and 10000")
    }
    return value, nil
}
```

This example defines application validation, not a loader or an Fx provider. At composition, decode the owned subtree and call `NewConfig` before exposing its result. Do not register both the decoded and validated value under the same unnamed Fx type. The Bricks configuration guide supplies the loader and wrapper binding.

## 4. Prove changed settings

Load the actual base, overlay, and environment inputs when those contracts change. Check invalid bounds and missing required secrets. Keep environment-changing tests nonparallel. Apply [Test policy](test-policy.md) before selecting the test target. Do not print credentials or entire configurations.

Done when consumers receive validated owned settings, precedence matches the published contract, and the changed loading path has execution evidence or an explicit verification gap.
