# Locale

Read when adding/changing coded module errors, locale files, language selection,
or asset publication for `i18n.Module`. Localized text belongs to the owning
module; the process owns the language configuration and framework infrastructure.

Use singular `locale/` in new modules. Bricks expects filenames `<language>.json`
at each contributed filesystem root. Its loader merges map-shaped JSON sections;
for errors, the section is `errors` keyed by stable code. This is not the exported
`i18n/dto.Locale` wrapper shape. Keep keys globally unique because merging repeated
keys overwrites them and Fx group order is unspecified.

`internal/modules/order/locale/en.json`.

```json
{"errors":{"ORDER_01":"Invalid order input","ORDER_02":"Order not found","ORDER_03":"Order access forbidden","ORDER_04":"Authentication required","ORDER_05":"Request body too large","ORDER_06":"Unsupported media type","ORDER_07":"Order conflict","ORDER_08":"Invalid order status","ORDER_09":"Invalid date","ORDER_10":"Dependency unavailable"}}
```

`internal/modules/order/locale/pt_BR.json`.

```json
{"errors":{"ORDER_01":"Dados do pedido inválidos","ORDER_02":"Pedido não encontrado","ORDER_03":"Acesso ao pedido negado","ORDER_04":"Autenticação necessária","ORDER_05":"Corpo da requisição excede o limite","ORDER_06":"Tipo de conteúdo não suportado","ORDER_07":"Conflito no pedido","ORDER_08":"Status do pedido inválido","ORDER_09":"Data inválida","ORDER_10":"Dependência indisponível"}}
```

`internal/modules/order/locale_fs.go`. The concrete provider is registered with
`group:"locale_filesystems"` in the module's `fx.go`; `i18n.Module` consumes it.

```go
package order

import (
	"embed"
	"io/fs"

	brickslocale "github.com/cristiano-pacheco/bricks/pkg/i18n/locale"
)

//go:embed locale/*.json
var localeFiles embed.FS

func provideLocaleFileSystem() (brickslocale.FileSystem, error) {
	files, err := fs.Sub(localeFiles, "locale")
	if err != nil {
		return brickslocale.FileSystem{}, err
	}
	return brickslocale.New(files), nil
}
```

The service always loads English fallback and then the configured language;
provide `en.json` even when the configured language is Portuguese. Malformed/
missing files are skipped by the baseline loader, so graph success alone cannot
prove key completeness. Compare every owned catalog code against every required
locale and exercise a translated outcome through the public decorated operation.

Translations reconstruct typed errors; [Error](error.md) owns the resulting
code/status versus pointer-identity contract. Do not translate or modify the
shared error singleton inside a repository, handler or use-case method.
