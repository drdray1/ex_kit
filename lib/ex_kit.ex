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

  alias ExKit.{Client, CustomFields, Forms, Subscribers, Tags}

  defdelegate new(api_key, opts \\ []), to: Client
  defdelegate create_subscriber(client, email, opts \\ []), to: Subscribers
  defdelegate add_subscriber_to_form(client, form_id, email, opts \\ []), to: Forms
  defdelegate list_forms(client, opts \\ []), to: Forms
  defdelegate tag_subscriber(client, tag_id, email, opts \\ []), to: Tags
  defdelegate list_tags(client, opts \\ []), to: Tags
  defdelegate create_tag(client, name), to: Tags
  defdelegate list_custom_fields(client, opts \\ []), to: CustomFields
  defdelegate create_custom_field(client, label), to: CustomFields
end
