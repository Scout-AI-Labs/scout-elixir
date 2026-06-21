# Changelog

All notable changes to this project are documented here. This project adheres
to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-06-21

Initial release.

- Built on [Req](https://hex.pm/packages/req).
- Full coverage of the Scout REST API: `Scout.Search`, `Scout.Page`, `Scout.Extract`, `Scout.Company`, `Scout.Lists`, `Scout.Products`, `Scout.Site`, `Scout.Jobs`, `Scout.Monitors`, `Scout.Chat.Completions`.
- `{:ok, body}` / `{:error, %Scout.Error{}}` return values, with `authentication?/1`, `rate_limited?/1`, and similar predicates.
- Automatic retries with exponential backoff and jitter, honoring `Retry-After`.
- Idempotency keys on writes.
- `list_all/1` helpers that walk every page.
