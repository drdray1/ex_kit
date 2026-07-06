defmodule ExKit.Subscribers do
  @moduledoc """
  Kit subscribers — the people in your account.
  """

  alias ExKit.{Client, Request}

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

  defp put_optional(map, _key, nil), do: map
  defp put_optional(map, key, value), do: Map.put(map, key, value)
end
