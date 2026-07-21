defmodule ExKit.Tags do
  @moduledoc """
  Kit tags — labels used to segment subscribers.
  """

  alias ExKit.{Client, Request}

  @list_params [:after, :before, :per_page, :include_total_count, :include]

  @doc """
  Lists the account's tags.

  `GET /v4/tags`. Options become query params:

    * `:after` / `:before` — pagination cursors.
    * `:per_page` — results per page (Kit defaults to 500, max 1000).
    * `:include_total_count` — set `true` to include a total count.
    * `:include` — comma-separated extras, e.g. `"subscriber_count"`.

  Returns `{:ok, %{"tags" => [...], "pagination" => %{...}}}`.
  """
  @spec list_tags(Client.t(), keyword()) :: Request.response()
  def list_tags(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/tags", params: Request.query_params(opts, @list_params))
  end

  @doc """
  Creates a tag.

  `POST /v4/tags`. Idempotent on name (matched case-insensitively): an existing
  tag comes back with `200` instead of `201`, so this doubles as a safe
  find-or-create. Returns `{:ok, %{"tag" => %{"id" => ..., "name" => ...}}}`.
  """
  @spec create_tag(Client.t(), String.t()) :: Request.response()
  def create_tag(%Client{} = client, name) when is_binary(name) do
    Request.request(client, :post, "/tags", json: %{name: name})
  end

  @doc """
  Tags a subscriber by email address.

  `POST /v4/tags/{tag_id}/subscribers`. The subscriber is upserted if they don't
  already exist. Returns `{:ok, %{"subscriber" => %{...}}}`.
  """
  @spec tag_subscriber(Client.t(), String.t() | integer(), String.t(), keyword()) ::
          Request.response()
  def tag_subscriber(%Client{} = client, tag_id, email, _opts \\ []) when is_binary(email) do
    Request.request(client, :post, "/tags/#{tag_id}/subscribers", json: %{email_address: email})
  end

  @doc """
  Removes a tag from a subscriber identified by email address.

  `DELETE /v4/tags/{tag_id}/subscribers?email_address=...`. The mirror of
  `tag_subscriber/4`; use it when you only know the subscriber's email. Kit
  responds `204 No Content`, normalized to `{:ok, %{}}`.
  """
  @spec untag_subscriber(Client.t(), String.t() | integer(), String.t()) :: Request.response()
  def untag_subscriber(%Client{} = client, tag_id, email) when is_binary(email) do
    Request.request(client, :delete, "/tags/#{tag_id}/subscribers",
      params: [email_address: email]
    )
  end

  @doc """
  Removes a tag from a subscriber identified by Kit subscriber id.

  `DELETE /v4/tags/{tag_id}/subscribers/{subscriber_id}` — Kit's canonical
  removal endpoint. Kit responds `204 No Content`, normalized to `{:ok, %{}}`.
  """
  @spec untag_subscriber_by_id(Client.t(), String.t() | integer(), String.t() | integer()) ::
          Request.response()
  def untag_subscriber_by_id(%Client{} = client, tag_id, subscriber_id) do
    Request.request(client, :delete, "/tags/#{tag_id}/subscribers/#{subscriber_id}")
  end
end
