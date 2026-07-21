defmodule ExKit.Webhooks do
  @moduledoc """
  Kit webhooks — outbound `POST`s Kit makes to your URL when a subscriber event
  fires (activate, unsubscribe, bounce, form subscribe, sequence complete, …).

  Use them to react to audience changes without polling. Register a URL against
  an event, and Kit delivers a JSON payload to it each time the event triggers.
  """

  alias ExKit.{Client, Request}

  @list_params [:after, :before, :per_page, :include_total_count]

  @doc """
  Lists the account's webhooks.

  `GET /v4/webhooks`. Options are the pagination params (`:after`, `:before`,
  `:per_page`, `:include_total_count`). Returns
  `{:ok, %{"webhooks" => [...], "pagination" => %{...}}}`.
  """
  @spec list_webhooks(Client.t(), keyword()) :: Request.response()
  def list_webhooks(%Client{} = client, opts \\ []) do
    Request.request(client, :get, "/webhooks", params: Request.query_params(opts, @list_params))
  end

  @doc """
  Creates a webhook.

  `POST /v4/webhooks`. `target_url` is the URL Kit will `POST` to; `event` is a
  map describing what to listen for — at minimum `%{name: "..."}`, plus any
  initiator id the event requires:

      ExKit.Webhooks.create_webhook(client, "https://example.com/hook", %{
        name: "subscriber.tag_add",
        tag_id: 207
      })

  Event names include `"subscriber.subscriber_activate"`,
  `"subscriber.subscriber_unsubscribe"`, `"subscriber.subscriber_bounce"`,
  `"subscriber.subscriber_complain"`, `"subscriber.form_subscribe"` (needs
  `form_id`), `"subscriber.tag_add"`/`"subscriber.tag_remove"` (needs `tag_id`),
  and `"subscriber.sequence_complete"` (needs `sequence_id`). The `event` map is
  passed straight through, so any field Kit accepts (`form_id`, `tag_id`,
  `sequence_id`, `product_id`, `initiator_value`, `custom_field_id`) can be set.

  Returns `{:ok, %{"webhook" => %{"id" => ..., "target_url" => ..., ...}}}`.
  """
  @spec create_webhook(Client.t(), String.t(), map()) :: Request.response()
  def create_webhook(%Client{} = client, target_url, event)
      when is_binary(target_url) and is_map(event) do
    Request.request(client, :post, "/webhooks", json: %{target_url: target_url, event: event})
  end

  @doc """
  Deletes a webhook by id.

  `DELETE /v4/webhooks/{webhook_id}`. Returns `{:ok, %{}}` on the `204 No
  Content` success, `{:error, :not_found}` when the id is unknown, and
  `{:error, {:unprocessable, body}}` when the webhook cannot be deleted.
  """
  @spec delete_webhook(Client.t(), String.t() | integer()) :: Request.response()
  def delete_webhook(%Client{} = client, webhook_id) do
    Request.request(client, :delete, "/webhooks/#{webhook_id}")
  end
end
