defmodule Scout.Client do
  @moduledoc """
  Core HTTP client for the Scout API.

  Build one with `new/1`, then pass it to the resource modules
  (`Scout.Search`, `Scout.Page`, ...). Built on [Req](https://hex.pm/packages/req).
  """

  alias Scout.Error

  @enforce_keys [:api_key, :base_url, :timeout, :max_retries]
  defstruct [:api_key, :base_url, :timeout, :max_retries]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          timeout: non_neg_integer(),
          max_retries: non_neg_integer()
        }

  @sdk_version "0.1.0"
  @api_version "2026-06-21"
  @default_base_url "https://core.usescout.sh"
  @default_timeout 60_000
  @default_max_retries 2
  @retry_statuses [408, 409, 429, 500, 502, 503, 504]

  @doc """
  Build a client. The API key defaults to the `SCOUT_API_KEY` environment
  variable.

  ## Options

    * `:api_key` - API key (falls back to `SCOUT_API_KEY`)
    * `:base_url` - API origin (default `#{@default_base_url}`)
    * `:timeout` - per-request timeout in ms (default `#{@default_timeout}`)
    * `:max_retries` - retries for transient failures (default `#{@default_max_retries}`)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    api_key = opts[:api_key] || System.get_env("SCOUT_API_KEY")

    if is_nil(api_key) or api_key == "" do
      raise Error, message: "Missing API key. Pass :api_key or set SCOUT_API_KEY."
    end

    %__MODULE__{
      api_key: api_key,
      base_url: String.trim_trailing(opts[:base_url] || @default_base_url, "/"),
      timeout: opts[:timeout] || @default_timeout,
      max_retries: opts[:max_retries] || @default_max_retries
    }
  end

  @doc false
  @spec request(t(), atom(), String.t(), keyword()) :: {:ok, any()} | {:error, Error.t()}
  def request(%__MODULE__{} = client, method, path, opts \\ []) do
    body = opts[:json]
    params = opts[:params]
    idempotency_key = if method != :get, do: gen_id(), else: nil
    do_request(client, method, path, body, params, idempotency_key, 0)
  end

  defp do_request(client, method, path, body, params, idem, attempt) do
    case attempt_once(client, method, path, body, params, idem) do
      {:ok, result} ->
        {:ok, result}

      {:error, %Error{} = err} ->
        if retriable?(err) and attempt < client.max_retries do
          Process.sleep(backoff(attempt, err))
          do_request(client, method, path, body, params, idem, attempt + 1)
        else
          {:error, err}
        end
    end
  end

  defp attempt_once(client, method, path, body, params, idem) do
    req_opts =
      [
        method: method,
        url: client.base_url <> path,
        headers: build_headers(client, idem),
        receive_timeout: client.timeout,
        retry: false
      ]
      |> maybe_put(:json, body)
      |> maybe_put(:params, params && compact(params))

    case Req.request(req_opts) do
      {:ok, %Req.Response{status: status, body: resp_body, headers: headers}} ->
        h = normalize_headers(headers)

        if status in 200..299 do
          {:ok, resp_body}
        else
          {:error, Error.from_response(status, resp_body, h)}
        end

      {:error, exception} ->
        {:error, Error.connection(Exception.message(exception))}
    end
  end

  defp build_headers(client, idem) do
    base = [
      {"authorization", "Bearer " <> client.api_key},
      {"accept", "application/json"},
      {"user-agent", "scout-elixir/" <> @sdk_version},
      {"scout-version", @api_version}
    ]

    if idem, do: [{"idempotency-key", idem} | base], else: base
  end

  defp retriable?(%Error{status: nil}), do: true
  defp retriable?(%Error{status: status}), do: status in @retry_statuses

  defp backoff(attempt, %Error{headers: headers}) do
    case parse_retry_after(headers["retry-after"]) do
      nil ->
        base = min(500 * Bitwise.bsl(1, attempt), 8_000)
        round(base * (0.5 + :rand.uniform() * 0.5))

      seconds ->
        min(round(seconds * 1000), 60_000)
    end
  end

  defp parse_retry_after(nil), do: nil

  defp parse_retry_after(value) do
    case Float.parse(value) do
      {seconds, _} -> seconds
      :error -> nil
    end
  end

  defp normalize_headers(headers) when is_map(headers) do
    Map.new(headers, fn {k, v} ->
      {String.downcase(k), if(is_list(v), do: List.first(v), else: v)}
    end)
  end

  defp normalize_headers(headers) when is_list(headers) do
    Map.new(headers, fn {k, v} -> {String.downcase(k), v} end)
  end

  defp compact(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp gen_id do
    "idmp-" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
  end
end
