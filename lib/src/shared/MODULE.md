# shared

**Path:** `lib/src/shared/` · **Layer:** shared widgets and app-wide providers

## Components

| File | Use |
| --- | --- |
| `app_loader.dart` | `AppLoader` — loading state |
| `app_error.dart` | `AppError(message, onRetry)` — error state |
| `app_empty_widget.dart` | `AppEmptyWidget(title, message, icon, action)` — empty state |
| `app_confirmation.dart` | `showAppConfirmation(...)` → `bool`; `destructive: true` for deletes |
| `app_snack_bar.dart` | `'message'.showSnackBar()` from widgets or notifiers |

## Providers

- `busyOperationsProvider` (keepAlive) — counter of running imports/copies/transactions. Wrap them in `ref.read(busyOperationsProvider.notifier).track(() => ...)`. The update banner disables **Restart now** while it is above zero.
