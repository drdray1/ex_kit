defmodule ExKit.CustomFields do
  @moduledoc """
  Kit custom fields — extra per-subscriber attributes (phone, interest, …).

  A field must exist in the account before it can be set on a subscriber via
  `ExKit.Subscribers.create_subscriber/3`'s `:fields` option; the field's `key`
  is what goes in that map.
  """

  alias ExKit.{Client, Request}

  @list_params [:after, :before, :per_page, :include_total_count]

  @doc """
  Lists the account's custom fields.

  `GET /v4/custom_fields`. Options become query params:

    * `:after` / `:before` — pagination cursors.
    * `:per_page` — results per page (Kit defaults to 500, max 1000).
    * `:include_total_count` — set `true` to include a total count.

  Returns `{:ok, %{"custom_fields" => [...], "pagination" => %{...}}}` — each
  field carries `"id"`, `"key"`, `"label"`, and the internal `"name"`.
  """
  @spec list_custom_fields(Client.t(), keyword()) :: Request.response()
  def list_custom_fields(%Client{} = client, opts \\ []) do
    Request.request(
      client,
      :get,
      "/custom_fields",
      params: Request.query_params(opts, @list_params)
    )
  end

  @doc """
  Creates a custom field.

  `POST /v4/custom_fields`. Kit derives the field's `key` (lowercased,
  underscored) and internal `name` from the label, which must be unique to the
  account; an existing label comes back with `200` instead of `201`. Returns
  `{:ok, %{"custom_field" => %{"id" => ..., "key" => ..., "label" => ...}}}`.
  """
  @spec create_custom_field(Client.t(), String.t()) :: Request.response()
  def create_custom_field(%Client{} = client, label) when is_binary(label) do
    Request.request(client, :post, "/custom_fields", json: %{label: label})
  end
end
