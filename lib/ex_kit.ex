defmodule ExKit do
  @moduledoc """
  Elixir client for the [Kit](https://kit.com) (formerly ConvertKit) v4 API.

  Kit is an email-marketing platform; this library covers the pieces a website
  needs to funnel signups into a Kit audience — upserting subscribers, adding
  them to a form, and tagging them.

  ## Usage

      client = ExKit.new("kit_v4_api_key")

      # Upsert a subscriber (creates if new, updates first_name if existing):
      {:ok, %{"subscriber" => sub}} =
        ExKit.create_subscriber(client, "alice@example.com", first_name: "Alice")

      # Add them to a form (fires the form's automations, records attribution):
      {:ok, _} = ExKit.add_subscriber_to_form(client, 234, "alice@example.com")

      # Tag them for segmentation:
      {:ok, _} = ExKit.tag_subscriber(client, 207, "alice@example.com")

  Manage the rest of the opt-in lifecycle — read a subscriber's current state,
  remove a tag, or unsubscribe them:

      {:ok, %{"subscriber" => sub}} = ExKit.get_subscriber(client, 349)
      {:ok, %{"tags" => tags}} = ExKit.list_subscriber_tags(client, 349)
      {:ok, _} = ExKit.untag_subscriber(client, 207, "alice@example.com")
      {:ok, _} = ExKit.unsubscribe(client, 349)

  React to audience changes without polling by registering webhooks:

      {:ok, %{"webhook" => hook}} =
        ExKit.create_webhook(client, "https://example.com/hook", %{
          name: "subscriber.subscriber_unsubscribe"
        })

  Discovery — find the ids/keys the calls above need (and set up tags/fields)
  without leaving `iex`:

      {:ok, %{"forms" => forms}} = ExKit.list_forms(client)
      {:ok, %{"tags" => tags}} = ExKit.list_tags(client)
      {:ok, %{"custom_fields" => fields}} = ExKit.list_custom_fields(client)

      # Both creates are idempotent find-or-creates:
      {:ok, %{"tag" => tag}} = ExKit.create_tag(client, "Website Lead")
      {:ok, %{"custom_field" => field}} = ExKit.create_custom_field(client, "Phone")

  Every call returns `{:ok, body}` or `{:error, reason}`, where `reason` is one
  of `:unauthorized`, `:not_found`, `:rate_limited`,
  `{:unprocessable, body}`, `{:unexpected_status, status}`, or
  `{:connection_error, reason}`.

  Authentication uses Kit's `X-Kit-Api-Key` header — see `ExKit.Client`.
  """

  alias ExKit.{Client, CustomFields, Forms, Subscribers, Tags, Webhooks}

  defdelegate new(api_key, opts \\ []), to: Client
  defdelegate create_subscriber(client, email, opts \\ []), to: Subscribers
  defdelegate get_subscriber(client, subscriber_id), to: Subscribers
  defdelegate list_subscribers(client, opts \\ []), to: Subscribers
  defdelegate list_subscriber_tags(client, subscriber_id, opts \\ []), to: Subscribers
  defdelegate unsubscribe(client, subscriber_id), to: Subscribers
  defdelegate add_subscriber_to_form(client, form_id, email, opts \\ []), to: Forms
  defdelegate list_forms(client, opts \\ []), to: Forms
  defdelegate tag_subscriber(client, tag_id, email, opts \\ []), to: Tags
  defdelegate untag_subscriber(client, tag_id, email), to: Tags
  defdelegate untag_subscriber_by_id(client, tag_id, subscriber_id), to: Tags
  defdelegate list_tags(client, opts \\ []), to: Tags
  defdelegate create_tag(client, name), to: Tags
  defdelegate list_custom_fields(client, opts \\ []), to: CustomFields
  defdelegate create_custom_field(client, label), to: CustomFields
  defdelegate list_webhooks(client, opts \\ []), to: Webhooks
  defdelegate create_webhook(client, target_url, event), to: Webhooks
  defdelegate delete_webhook(client, webhook_id), to: Webhooks
end
