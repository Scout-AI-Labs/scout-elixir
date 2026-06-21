# Resource modules - a faithful 1:1 mirror of the REST API tags.
# Each function takes a %Scout.Client{} and returns {:ok, body} | {:error, %Scout.Error{}}.

defmodule Scout.Search do
  @moduledoc "Web search, agentic AI queries, and search-run history."
  alias Scout.{Client, Pagination}

  def create(client, params), do: Client.request(client, :post, "/v1/search", json: params)
  def ai_query(client, params), do: Client.request(client, :post, "/v1/ai-query", json: params)

  def list(client, opts \\ []) do
    Client.request(client, :get, "/v1/searches",
      params: %{limit: opts[:limit], offset: opts[:offset]}
    )
  end

  def list_all(client), do: Pagination.all(client, "/v1/searches")
  def get(client, id), do: Client.request(client, :get, "/v1/searches/#{id}")
  def cancel(client, id), do: Client.request(client, :post, "/v1/searches/#{id}/cancel")
  def events(client, id), do: Client.request(client, :get, "/v1/searches/#{id}/events")
end

defmodule Scout.Page do
  @moduledoc "Single-page operations: markdown, html, screenshot, images, extract."
  alias Scout.Client

  def markdown(client, params), do: Client.request(client, :post, "/v1/page/markdown", json: params)
  def html(client, params), do: Client.request(client, :post, "/v1/page/html", json: params)

  def screenshot(client, params),
    do: Client.request(client, :post, "/v1/page/screenshot", json: params)

  def images(client, params), do: Client.request(client, :post, "/v1/page/images", json: params)
  def extract(client, params), do: Client.request(client, :post, "/v1/page/extract", json: params)
end

defmodule Scout.Extract do
  @moduledoc "Multi-URL structured extraction."
  alias Scout.Client

  def create(client, params), do: Client.request(client, :post, "/v1/extract", json: params)
end

defmodule Scout.Company do
  @moduledoc "Company enrichment: profiles, logos, fonts, industry codes, styleguide."
  alias Scout.Client

  def enrich(client, params), do: Client.request(client, :post, "/v1/company", json: params)
  def by_email(client, params), do: Client.request(client, :post, "/v1/company/by-email", json: params)
  def by_name(client, params), do: Client.request(client, :post, "/v1/company/by-name", json: params)

  def by_ticker(client, params),
    do: Client.request(client, :post, "/v1/company/by-ticker", json: params)

  def simple(client, params), do: Client.request(client, :post, "/v1/company/simple", json: params)
  def fonts(client, params), do: Client.request(client, :post, "/v1/company/fonts", json: params)

  def styleguide(client, params),
    do: Client.request(client, :post, "/v1/company/styleguide", json: params)

  def logo(client, params), do: Client.request(client, :post, "/v1/company/logo", json: params)
end

defmodule Scout.Lists do
  @moduledoc ~S"""
  Find-all ("lists"): build a list of entities matching a query, then enrich
  or extend the run.
  """
  alias Scout.Client

  def create(client, params), do: Client.request(client, :post, "/v1/lists", json: params)
  def run(client, params), do: Client.request(client, :post, "/v1/lists/runs", json: params)
end

defmodule Scout.Lists.Runs do
  @moduledoc "Operations on async find-all runs."
  alias Scout.{Client, Pagination}

  def list(client, opts \\ []) do
    Client.request(client, :get, "/v1/lists/runs",
      params: %{limit: opts[:limit], offset: opts[:offset]}
    )
  end

  def list_all(client), do: Pagination.all(client, "/v1/lists/runs")
  def get(client, id), do: Client.request(client, :get, "/v1/lists/runs/#{id}")
  def cancel(client, id), do: Client.request(client, :post, "/v1/lists/runs/#{id}/cancel")

  def enrich(client, id, body \\ %{}),
    do: Client.request(client, :post, "/v1/lists/runs/#{id}/enrich", json: body)

  def extend(client, id, body \\ %{}),
    do: Client.request(client, :post, "/v1/lists/runs/#{id}/extend", json: body)

  def events(client, id), do: Client.request(client, :get, "/v1/lists/runs/#{id}/events")
end

defmodule Scout.Products do
  @moduledoc "Product extraction from storefronts."
  alias Scout.Client

  def extract(client, params), do: Client.request(client, :post, "/v1/products", json: params)
  def one(client, params), do: Client.request(client, :post, "/v1/products/one", json: params)
end

defmodule Scout.Site do
  @moduledoc "Whole-site operations: crawl and sitemap discovery."
  alias Scout.Client

  def crawl(client, params), do: Client.request(client, :post, "/v1/site/crawl", json: params)
  def map(client, params), do: Client.request(client, :post, "/v1/site/map", json: params)
end

defmodule Scout.Jobs do
  @moduledoc ~S'Async tasks ("jobs"): submit a task, then poll or stream events.'
  alias Scout.{Client, Pagination}

  def create(client, params), do: Client.request(client, :post, "/v1/jobs", json: params)

  def list(client, opts \\ []) do
    Client.request(client, :get, "/v1/jobs", params: %{limit: opts[:limit], offset: opts[:offset]})
  end

  def list_all(client), do: Pagination.all(client, "/v1/jobs")
  def get(client, id), do: Client.request(client, :get, "/v1/jobs/#{id}")
  def cancel(client, id), do: Client.request(client, :post, "/v1/jobs/#{id}/cancel")
  def events(client, id), do: Client.request(client, :get, "/v1/jobs/#{id}/events")
  def start_run(client, body \\ %{}), do: Client.request(client, :post, "/v1/jobs/runs", json: body)
  def run_result(client, id), do: Client.request(client, :get, "/v1/jobs/runs/#{id}")
  def run_events(client, id), do: Client.request(client, :get, "/v1/jobs/runs/#{id}/events")
end

defmodule Scout.Monitors do
  @moduledoc ~S'Scheduled searches ("monitors"): run a query on a cadence, deliver via webhook.'
  alias Scout.{Client, Pagination}

  def create(client, params), do: Client.request(client, :post, "/v1/monitors", json: params)

  def list(client, opts \\ []) do
    Client.request(client, :get, "/v1/monitors",
      params: %{limit: opts[:limit], offset: opts[:offset]}
    )
  end

  def list_all(client), do: Pagination.all(client, "/v1/monitors")
  def get(client, id), do: Client.request(client, :get, "/v1/monitors/#{id}")
  def update(client, id, params), do: Client.request(client, :patch, "/v1/monitors/#{id}", json: params)
  def delete(client, id), do: Client.request(client, :delete, "/v1/monitors/#{id}")
  def pause(client, id), do: Client.request(client, :post, "/v1/monitors/#{id}/pause")
  def resume(client, id), do: Client.request(client, :post, "/v1/monitors/#{id}/resume")
  def run(client, id), do: Client.request(client, :post, "/v1/monitors/#{id}/run")
  def events(client, id), do: Client.request(client, :get, "/v1/monitors/#{id}/events")
end

defmodule Scout.Chat.Completions do
  @moduledoc "Creates chat completions."
  alias Scout.Client

  def create(client, params),
    do: Client.request(client, :post, "/v1/chat/completions", json: params)
end

defmodule Scout.Chat do
  @moduledoc "OpenAI-compatible chat completions, optionally grounded with web search."
end
