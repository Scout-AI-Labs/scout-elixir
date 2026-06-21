defmodule Scout do
  @moduledoc """
  Elixir SDK for the [Scout](https://usescout.sh) web-intelligence API: search,
  scrape, screenshot, extract, crawl, and company enrichment.

      client = Scout.new()              # reads SCOUT_API_KEY
      {:ok, results} = Scout.Search.create(client, %{queries: ["climate tech startups"]})

  Build a client with `new/1`, then call the resource modules: `Scout.Search`,
  `Scout.Page`, `Scout.Extract`, `Scout.Company`, `Scout.Lists`, `Scout.Products`,
  `Scout.Site`, `Scout.Jobs`, `Scout.Monitors`, and `Scout.Chat.Completions`.
  Every call returns `{:ok, body}` or `{:error, %Scout.Error{}}`.
  """

  @doc "Build a client. See `Scout.Client.new/1`."
  defdelegate new(opts \\ []), to: Scout.Client
end
