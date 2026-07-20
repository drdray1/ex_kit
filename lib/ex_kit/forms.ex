defmodule ExKit.Forms do
  @moduledoc """
  Kit forms — the opt-in units website signups are attributed to.
  """

  alias ExKit.{Client, Request}

  @list_params [:after, :before, :per_page, :include_total_count, :include, :status, :type]

  @doc """
  Lists the account's forms (and landing pages).

  `GET /v4/forms`. Options become query params:

    * `:after` / `:before` — pagination cursors.
    * `:per_page` — results per page (Kit defaults to 500, max 1000).
    * `:include_total_count` — set `true` to include a total count.
    * `:include` — comma-separated extras, e.g. `"subscriber_count"`.
    * `:status` — `"active"` (Kit's default), `"archived"`, `"trashed"`, or
      `"all"`.
    * `:type` — `"embed"` (embedded forms) or `"hosted"` (landing pages).

  Returns `{:ok, %{"forms" => [...], "pagination" => %{...}}}`.
  """
  @spec list_forms(Client.t(), keyword()) :: Request.response()
  def list_forms(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/forms", params: Request.query_params(opts, @list_params))
  end

  @doc """
  Adds a subscriber to a form by email address.

  `POST /v4/forms/{form_id}/subscribers`. Kit recommends creating the subscriber
  first (see `ExKit.Subscribers.create_subscriber/3`) so their `first_name` and
  custom fields are set, then adding them to the form to trigger any form-based
  automations and record the signup.

  Options:

    * `:referrer` — the referring URL (may carry UTM params), stored on the
      subscriber's form entry.

  Returns `{:ok, %{"subscriber" => %{...}}}`.
  """
  @spec add_subscriber_to_form(Client.t(), String.t() | integer(), String.t(), keyword()) ::
          Request.response()
  def add_subscriber_to_form(%Client{} = client, form_id, email, opts \\ [])
      when is_binary(email) do
    body =
      %{email_address: email}
      |> put_optional(:referrer, opts[:referrer])

    Request.request(client, :post, "/forms/#{form_id}/subscribers", json: body)
  end

  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)
end
