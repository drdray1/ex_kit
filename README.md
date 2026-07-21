# ExKit

Elixir client for the [Kit](https://kit.com) (formerly ConvertKit) **v4** API —
the pieces a website needs to funnel signups into a Kit audience and manage the
opt-in lifecycle: upserting subscribers, adding them to a form, tagging and
untagging, reading subscriber state, unsubscribing, and reacting to events via
webhooks.

Built in the same style as its sibling clients (Req + Jason, a small client
struct, `{:ok, _}` / `{:error, _}` returns, `Req.Test`-backed tests).

## Installation

```elixir
def deps do
  [
    {:ex_kit, git: "https://github.com/drdray1/ex_kit.git", tag: "0.3.0"}
  ]
end
```

## Usage

```elixir
client = ExKit.new("kit_v4_api_key")

# Upsert a subscriber (creates if new, updates first_name if existing):
{:ok, %{"subscriber" => sub}} =
  ExKit.create_subscriber(client, "alice@example.com", first_name: "Alice")

# Add them to a form — fires the form's automations and records attribution:
{:ok, _} = ExKit.add_subscriber_to_form(client, 234, "alice@example.com")

# Tag them for segmentation:
{:ok, _} = ExKit.tag_subscriber(client, 207, "alice@example.com")

# Read their current state and tags:
{:ok, %{"subscriber" => sub}} = ExKit.get_subscriber(client, sub["id"])
{:ok, %{"tags" => tags}} = ExKit.list_subscriber_tags(client, sub["id"])

# Untag or unsubscribe them:
{:ok, _} = ExKit.untag_subscriber(client, 207, "alice@example.com")
{:ok, _} = ExKit.unsubscribe(client, sub["id"])

# React to audience events without polling:
{:ok, %{"webhook" => hook}} =
  ExKit.create_webhook(client, "https://example.com/hook", %{
    name: "subscriber.subscriber_unsubscribe"
  })
```

Every call returns `{:ok, body}` (the decoded JSON map, e.g.
`%{"subscriber" => %{...}}`) or `{:error, reason}`, where `reason` is one of:

| reason | meaning |
| --- | --- |
| `:unauthorized` | `401`/`403` — bad or missing API key |
| `:not_found` | `404` — no such subscriber/form/tag/webhook |
| `:rate_limited` | `429` — over the rate limit |
| `{:unprocessable, body}` | `422` — validation error (body carries the detail) |
| `{:unexpected_status, status}` | any other `>= 400` |
| `{:connection_error, reason}` | transport failure |

## Authentication

`ExKit.new/2` takes a Kit **v4 API key**, sent on every request as the
`X-Kit-Api-Key` header. This is Kit's API-key mode — meant for programmatic
access to your own account (rate-limited to 120 requests / rolling 60s). Some
Kit endpoints (bulk, purchases) require OAuth instead and are out of scope here.

Generate a v4 API key in your Kit account under **Settings → Advanced →
API / Developer**.

## Options

`ExKit.new/2` accepts:

- `:base_url` — override the API base (defaults to `https://api.kit.com/v4`).
- `:plug` — a `{Req.Test, StubName}` tuple to intercept requests in tests.

## The API

Every function takes the `client` as its first argument and returns
`{:ok, body}` / `{:error, reason}`.

### Subscribers

- `ExKit.create_subscriber/3` — `POST /v4/subscribers` (upsert: creates if new,
  updates if the email is known). Options: `:first_name`, `:state`, `:fields`
  (custom fields must pre-exist in Kit).
- `ExKit.get_subscriber/2` — `GET /v4/subscribers/{id}`.
- `ExKit.list_subscribers/2` — `GET /v4/subscribers`. Filter options:
  `:status`, `:email_address` (resolve an email to its subscriber id),
  `:created_after`, `:created_before`, `:sort_field`, `:sort_order`, `:tag_id`,
  plus pagination.
- `ExKit.list_subscriber_tags/3` — `GET /v4/subscribers/{id}/tags`.
- `ExKit.unsubscribe/2` — `POST /v4/subscribers/{id}/unsubscribe`. Sets the
  subscriber's state to `"cancelled"`; returns `{:ok, %{}}`.

### Forms

- `ExKit.list_forms/2` — `GET /v4/forms`. Options: `:status` (`"active"` |
  `"archived"` | `"trashed"` | `"all"`), `:type` (`"embed"` | `"hosted"`), plus
  pagination.
- `ExKit.add_subscriber_to_form/4` — `POST /v4/forms/{form_id}/subscribers`.
  Fires the form's automations and records attribution. Option: `:referrer`.

### Tags

- `ExKit.list_tags/2` — `GET /v4/tags`.
- `ExKit.create_tag/2` — `POST /v4/tags`. Idempotent on name (an existing tag
  is returned rather than duplicated), so it's a safe find-or-create.
- `ExKit.tag_subscriber/4` — `POST /v4/tags/{tag_id}/subscribers` (by email).
  Option: `:referrer` (records signup attribution, as with the form call).
- `ExKit.untag_subscriber/3` — `DELETE /v4/tags/{tag_id}/subscribers` (by
  email); the mirror of `tag_subscriber/4`. Returns `{:ok, %{}}`.
- `ExKit.untag_subscriber_by_id/3` — `DELETE
  /v4/tags/{tag_id}/subscribers/{subscriber_id}` (by subscriber id). Returns
  `{:ok, %{}}`.

### Custom fields

- `ExKit.list_custom_fields/2` — `GET /v4/custom_fields`. Each field's `"key"`
  is what `create_subscriber`'s `:fields` map uses.
- `ExKit.create_custom_field/2` — `POST /v4/custom_fields`. Idempotent on label.

### Webhooks

React to subscriber events (activate, unsubscribe, bounce, form subscribe,
sequence complete, …) without polling — Kit `POST`s a JSON payload to your URL
each time the event fires.

- `ExKit.list_webhooks/2` — `GET /v4/webhooks`.
- `ExKit.create_webhook/3` — `POST /v4/webhooks`. Takes a `target_url` and an
  `event` map, at minimum `%{name: "..."}` plus any initiator id the event
  needs (e.g. `%{name: "subscriber.tag_add", tag_id: 207}`). Event names
  include `"subscriber.subscriber_activate"`,
  `"subscriber.subscriber_unsubscribe"`, `"subscriber.subscriber_bounce"`,
  `"subscriber.subscriber_complain"`, `"subscriber.form_subscribe"` (`form_id`),
  `"subscriber.tag_add"` / `"subscriber.tag_remove"` (`tag_id`), and
  `"subscriber.sequence_complete"` (`sequence_id`).
- `ExKit.delete_webhook/2` — `DELETE /v4/webhooks/{id}`. Returns `{:ok, %{}}`.

### Notes

List endpoints accept Kit's cursor pagination options: `:after`, `:before`,
`:per_page` (default 500, max 1000), `:include_total_count`, and — where Kit
supports it (forms, tags) — `:include` (e.g. `"subscriber_count"`).

Kit's create-subscriber endpoint is an upsert, but for a website form the usual
flow is: **create the subscriber first** (so `first_name`/fields are set), then
add them to a form and/or tag them.

Tagging and untagging work by email for convenience, while `get_subscriber`,
`list_subscriber_tags`, and `unsubscribe` take a Kit **subscriber id** — use
`list_subscribers(email_address: "...")` to resolve an email to its id when you
only have the address.

## Development

```sh
mix deps.get
mix test
mix credo
mix format --check-formatted
```

## License

MIT.
