defmodule Scout.Error do
  @moduledoc """
  Error raised or returned by the SDK. Carries the HTTP status, parsed body,
  request id, and a machine-readable code when available.
  """

  defexception [:message, :status, :request_id, :code, :body, :headers]

  @type t :: %__MODULE__{
          message: String.t(),
          status: integer() | nil,
          request_id: String.t() | nil,
          code: String.t() | nil,
          body: any(),
          headers: map()
        }

  @status_messages %{
    400 => "bad request",
    401 => "authentication failed",
    402 => "insufficient credits",
    403 => "permission denied",
    404 => "not found",
    409 => "conflict",
    422 => "unprocessable entity",
    429 => "rate limit exceeded"
  }

  @doc false
  def from_response(status, body, headers) do
    %__MODULE__{
      message: message_from(body, status),
      status: status,
      request_id: headers["x-request-id"],
      code: code_from(body),
      body: body,
      headers: headers
    }
  end

  @doc false
  def connection(message) do
    %__MODULE__{message: message, headers: %{}}
  end

  @doc "True when the error is an HTTP 401."
  def authentication?(%__MODULE__{status: 401}), do: true
  def authentication?(_), do: false

  @doc "True when the error is an HTTP 402."
  def insufficient_credits?(%__MODULE__{status: 402}), do: true
  def insufficient_credits?(_), do: false

  @doc "True when the error is an HTTP 404."
  def not_found?(%__MODULE__{status: 404}), do: true
  def not_found?(_), do: false

  @doc "True when the error is an HTTP 429."
  def rate_limited?(%__MODULE__{status: 429}), do: true
  def rate_limited?(_), do: false

  @doc "True when the error is an HTTP 5xx."
  def server_error?(%__MODULE__{status: status}) when is_integer(status), do: status >= 500
  def server_error?(_), do: false

  defp message_from(body, status) when is_map(body) do
    cond do
      is_binary(body["detail"]) -> body["detail"]
      is_binary(body["error"]) -> body["error"]
      is_binary(body["message"]) -> body["message"]
      is_map(body["error"]) and is_binary(body["error"]["message"]) -> body["error"]["message"]
      true -> default_message(status)
    end
  end

  defp message_from(body, _status) when is_binary(body) and body != "", do: body
  defp message_from(_body, status), do: default_message(status)

  defp default_message(status) do
    Map.get(@status_messages, status, "Scout API returned HTTP #{status}")
  end

  defp code_from(body) when is_map(body) do
    cond do
      is_binary(body["code"]) -> body["code"]
      is_map(body["error"]) and is_binary(body["error"]["code"]) -> body["error"]["code"]
      true -> nil
    end
  end

  defp code_from(_), do: nil
end
