# ExKit

Elixir client for the [Kit](https://kit.com) (formerly ConvertKit) **v4** API —
the pieces a website needs to funnel signups into a Kit audience: upserting
subscribers, adding them to a form, and tagging them.

Built in the same style as its sibling clients (Req + Jason, a small client
struct, `{:ok, _}` / `{:error, _}` returns, `Req.Test`-backed tests).

## Installation

```elixir
def deps do
  [
    {:ex_kit, git: "https://github.com/drdray1/ex_kit.git", tag: "0.1.0"}
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
```

Every call returns `{:ok, body}` (the decoded JSON map, e.g.
`%{"subscriber" => %{...}}`) or `{:error, reason}`, where `reason` is one of:

| reason | meaning |
| --- | --- |
| `:unauthorized` | `401`/`403` — bad or missing API key |
| `:not_found` | `404` — no such form/tag |
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

- `ExKit.create_subscriber/3` — `POST /v4/subscribers` (upsert). Options:
  `:first_name`, `:state`, `:fields` (custom fields must pre-exist in Kit).
- `ExKit.add_subscriber_to_form/4` — `POST /v4/forms/{form_id}/subscribers`.
  Option: `:referrer`.
- `ExKit.tag_subscriber/4` — `POST /v4/tags/{tag_id}/subscribers`.

Kit's create-subscriber endpoint is an upsert, but for a website form the usual
flow is: **create the subscriber first** (so `first_name`/fields are set), then
add them to a form and/or tag them.

## Development

```sh
mix deps.get
mix test
mix credo
mix format --check-formatted
```

## License

MIT.
