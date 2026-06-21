# Scout Elixir SDK

Official Elixir SDK for the [Scout](https://usescout.sh) web-intelligence API: search, scrape, screenshot, extract, crawl, and company enrichment.

- Built on [Req](https://hex.pm/packages/req).
- Every call returns `{:ok, body}` or `{:error, %Scout.Error{}}`.
- Automatic retries with backoff and jitter, configurable timeouts, and idempotency keys on writes.

## Requirements

- Elixir 1.14+

## Installation

Add `scout_sdk` to your deps in `mix.exs`:

```elixir
def deps do
  [
    {:scout_sdk, "~> 0.1.0"}
  ]
end
```

## Authentication

Generate an API key at [platform.usescout.sh/settings](https://platform.usescout.sh/settings). The client reads `SCOUT_API_KEY` from the environment by default:

```elixir
client = Scout.new()                    # uses SCOUT_API_KEY
client = Scout.new(api_key: "sk_...")   # or pass it explicitly
```

## Quickstart

```elixir
client = Scout.new()

{:ok, results} =
  Scout.Search.create(client, %{
    queries: ["best climate tech startups 2026"],
    depth: "standard",
    country: "us"
  })
```

## Examples

```elixir
# Scrape a page to Markdown
{:ok, page} = Scout.Page.markdown(client, %{url: "https://example.com"})

# Structured extraction
{:ok, data} =
  Scout.Extract.create(client, %{
    urls: ["https://example.com/pricing"],
    output_schema: %{type: "object"}
  })

# Company enrichment + logo
{:ok, company} = Scout.Company.enrich(client, %{domain: "stripe.com"})
{:ok, logo} = Scout.Company.logo(client, %{domain: "stripe.com", format: "svg"})

# Crawl a site
{:ok, crawl} = Scout.Site.crawl(client, %{start_url: "https://example.com", max_pages: 50})

# Chat completion grounded with web search
{:ok, completion} =
  Scout.Chat.Completions.create(client, %{
    messages: [%{role: "user", content: "Summarize the latest on EU AI regulation."}],
    web_search: true
  })
```

## Error handling

Calls return `{:error, %Scout.Error{}}` on failure. The struct carries `status`, `request_id`, `code`, and the parsed `body`:

```elixir
case Scout.Search.create(client, %{queries: ["..."]}) do
  {:ok, results} ->
    results

  {:error, %Scout.Error{} = error} ->
    cond do
      Scout.Error.rate_limited?(error) -> "slow down"
      Scout.Error.authentication?(error) -> "check your API key"
      true -> "HTTP #{error.status}: #{error.message}"
    end
end
```

Predicates: `authentication?/1` (401), `insufficient_credits?/1` (402), `not_found?/1` (404), `rate_limited?/1` (429), `server_error?/1` (5xx).

## Retries & timeouts

Transient failures (connection errors, 408/409/429/5xx) are retried automatically, 2 times by default, with exponential backoff and jitter, honoring `Retry-After`. Write methods send an auto-generated idempotency key.

```elixir
client = Scout.new(timeout: 30_000, max_retries: 4)
```

## Pagination

```elixir
{:ok, runs} = Scout.Search.list_all(client)
```

## Streaming

Stream chat completions and live run progress (search, jobs, find-all, monitors). Both take a callback invoked per chunk/event:

```elixir
# Token-by-token chat
Scout.Chat.Completions.stream(
  client,
  %{messages: [%{role: "user", content: "Summarize EU AI regulation."}]},
  fn chunk ->
    IO.write(chunk["choices"] |> hd() |> get_in(["delta", "content"]) || "")
  end
)

# Live progress events from a deep-search run
Scout.Search.stream_events(client, search_id, fn event ->
  IO.puts(event["type"])
end)
```

`stream_events` is also available on `Scout.Jobs`, `Scout.Lists.Runs`, and `Scout.Monitors`.

## Versioning

This SDK follows [SemVer](https://semver.org/) and sends the targeted Scout API version on every request; see [`CHANGELOG.md`](./CHANGELOG.md). API reference renders on [HexDocs](https://hexdocs.pm/scout_sdk).

## Contributing

Issues and pull requests are welcome at [Scout-AI-Labs/scout-elixir](https://github.com/Scout-AI-Labs/scout-elixir).

## License

[MIT](./LICENSE)
