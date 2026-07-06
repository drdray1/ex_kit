defmodule ExKit.Tags do
  @moduledoc """
  Kit tags — labels used to segment subscribers.
  """

  alias ExKit.{Client, Request}

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
end
