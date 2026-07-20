defmodule ExKit.Request do
  @moduledoc """
  Low-level HTTP for an `ExKit.Client`.

  Every request carries the `X-Kit-Api-Key` header and a JSON `Content-Type`,
  hits the client's `base_url`, and is normalized to `{:ok, map}` /
  `{:error, reason}` by `handle_response/1`. Transient errors and `429`s are
  retried with exponential backoff in the real client and disabled under a test
  plug so stubbed responses return deterministically.
  """

  alias ExKit.Client

  @type response :: {:ok, map()} | {:error, term()}

  @doc """
  Builds a query-params keyword list from `opts`, keeping only `allowed` keys
  with non-nil values. Used by the list endpoints to pass pagination/filter
  options straight through to Kit.
  """
  @spec query_params(keyword(), [atom()]) :: keyword()
  def query_params(opts, allowed) do
    for key <- allowed, value = opts[key], value != nil, do: {key, value}
  end

  @doc """
  Performs `method` against `path` (relative to the client `base_url`) and
  normalizes the response. Pass a request body with `opts[:json]` and query
  params with `opts[:params]`.
  """
  @spec request(Client.t(), atom(), String.t(), keyword()) :: response()
  def request(%Client{} = client, method, path, opts \\ []) do
    req_opts =
      [
        method: method,
        base_url: client.base_url,
        url: path,
        headers: headers(client)
      ]
      |> Keyword.merge(retry_opts(client.plug))
      |> maybe_put(:json, Keyword.get(opts, :json))
      |> maybe_put(:params, Keyword.get(opts, :params))
      |> maybe_plug(client.plug)

    req_opts
    |> Req.request()
    |> handle_response()
  end

  @doc """
  Normalizes a Kit API response to `{:ok, body}` or `{:error, reason}`.

  Kit returns `200` (updated), `201` (created), and `202` (async processing) for
  successful writes; all map to `{:ok, body}`.
  """
  @spec handle_response({:ok, Req.Response.t()} | {:error, term()}) :: response()
  def handle_response({:ok, %Req.Response{status: status, body: body}})
      when status in 200..299,
      do: {:ok, body}

  def handle_response({:ok, %Req.Response{status: status}}) when status in [401, 403],
    do: {:error, :unauthorized}

  def handle_response({:ok, %Req.Response{status: 404}}), do: {:error, :not_found}

  def handle_response({:ok, %Req.Response{status: 422, body: body}}),
    do: {:error, {:unprocessable, body}}

  def handle_response({:ok, %Req.Response{status: 429}}), do: {:error, :rate_limited}

  def handle_response({:ok, %Req.Response{status: status}}) when status >= 400,
    do: {:error, {:unexpected_status, status}}

  def handle_response({:error, reason}), do: {:error, {:connection_error, reason}}

  # --- Headers ----------------------------------------------------------------

  defp headers(%Client{api_key: api_key}) do
    [
      {"x-kit-api-key", api_key || ""},
      {"accept", "application/json"}
    ]
  end

  # Retry transient errors / 429s in the real client; disable under a test plug
  # so stubbed error responses return immediately and deterministically.
  defp retry_opts(nil),
    do: [retry: :transient, max_retries: 3, retry_delay: &retry_delay/1]

  defp retry_opts(_plug), do: [retry: false]

  # Exponential backoff for transient errors / 429s.
  defp retry_delay(attempt), do: 500 * Integer.pow(2, attempt)

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp maybe_plug(opts, nil), do: opts
  defp maybe_plug(opts, plug), do: Keyword.put(opts, :plug, plug)
end
