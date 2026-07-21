defmodule ExKit.Subscribers do
  @moduledoc """
  Kit subscribers — the people in your account.
  """

  alias ExKit.{Client, Request}

  @list_params [
    :after,
    :before,
    :per_page,
    :include_total_count,
    :status,
    :email_address,
    :created_after,
    :created_before,
    :sort_field,
    :sort_order,
    :tag_id
  ]

  @tag_list_params [:after, :before, :per_page, :include_total_count]

  @doc """
  Creates (or updates) a subscriber by email address.

  `POST /v4/subscribers` is an upsert: it creates a new subscriber when the
  email is unknown and updates the existing one otherwise (returning `200`
  rather than `201`). Only the email is required.

  Options become body fields:

    * `:first_name` — the subscriber's first name.
    * `:state` — one of `"active"`, `"bounced"`, `"cancelled"`, `"complained"`,
      `"inactive"` (Kit defaults to `"active"`).
    * `:fields` — a map of custom field key/values (the fields must already
      exist in the Kit account).

  Returns `{:ok, %{"subscriber" => %{...}}}`.
  """
  @spec create_subscriber(Client.t(), String.t(), keyword()) :: Request.response()
  def create_subscriber(%Client{} = client, email, opts \\ []) when is_binary(email) do
    body =
      %{email_address: email}
      |> put_optional(:first_name, opts[:first_name])
      |> put_optional(:state, opts[:state])
      |> put_optional(:fields, opts[:fields])

    Request.request(client, :post, "/subscribers", json: body)
  end

  @doc """
  Fetches a single subscriber by Kit subscriber id.

  `GET /v4/subscribers/{subscriber_id}`. Returns
  `{:ok, %{"subscriber" => %{...}}}`, or `{:error, :not_found}` when unknown.
  """
  @spec get_subscriber(Client.t(), String.t() | integer()) :: Request.response()
  def get_subscriber(%Client{} = client, subscriber_id) do
    Request.request(client, :get, "/subscribers/#{subscriber_id}")
  end

  @doc """
  Lists the account's subscribers.

  `GET /v4/subscribers`. Options become query params:

    * `:after` / `:before` — pagination cursors.
    * `:per_page` — results per page (Kit defaults to 500, max 1000).
    * `:include_total_count` — set `true` to include a total count.
    * `:status` — `"active"` (Kit's default), `"bounced"`, `"cancelled"`,
      `"complained"`, `"inactive"`, or `"all"`.
    * `:email_address` — filter to an exact email address.
    * `:created_after` / `:created_before` — ISO8601 timestamps.
    * `:sort_field` / `:sort_order` — ordering controls.
    * `:tag_id` — filter to subscribers carrying a tag.

  Returns `{:ok, %{"subscribers" => [...], "pagination" => %{...}}}`.
  """
  @spec list_subscribers(Client.t(), keyword()) :: Request.response()
  def list_subscribers(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/subscribers",
      params: Request.query_params(opts, @list_params)
    )
  end

  @doc """
  Lists the tags currently applied to a subscriber.

  `GET /v4/subscribers/{subscriber_id}/tags`. Options are the pagination params
  (`:after`, `:before`, `:per_page`, `:include_total_count`). Returns
  `{:ok, %{"tags" => [...], "pagination" => %{...}}}`.
  """
  @spec list_subscriber_tags(Client.t(), String.t() | integer(), keyword()) ::
          Request.response()
  def list_subscriber_tags(%Client{} = client, subscriber_id, opts \\ []) do
    Request.request(client, :get, "/subscribers/#{subscriber_id}/tags",
      params: Request.query_params(opts, @tag_list_params)
    )
  end

  @doc """
  Unsubscribes a subscriber from all emails.

  `POST /v4/subscribers/{subscriber_id}/unsubscribe`. Sets the subscriber's
  state to `"cancelled"`; Kit responds `204 No Content`, normalized to
  `{:ok, %{}}`.
  """
  @spec unsubscribe(Client.t(), String.t() | integer()) :: Request.response()
  def unsubscribe(%Client{} = client, subscriber_id) do
    Request.request(client, :post, "/subscribers/#{subscriber_id}/unsubscribe")
  end

  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)
end
