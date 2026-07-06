defmodule ExKit.Client do
  @moduledoc """
  Holds the connection settings for the Kit v4 API — the API key, the base URL,
  and an optional `Req.Test` plug for tests.

  Build one with `ExKit.new/2` and pass it to every resource call:

      client = ExKit.new("kit_v4_api_key")
      ExKit.create_subscriber(client, "alice@example.com", first_name: "Alice")

  The API key is sent as the `X-Kit-Api-Key` header (Kit's API-key auth mode,
  rate-limited to 120 requests / rolling 60s). To use an OAuth bearer token
  instead, set `:base_url`/headers via a custom integration — this client
  targets the simpler API-key flow used for personal-account automation.
  """

  @default_base_url "https://api.kit.com/v4"

  @type t :: %__MODULE__{
          api_key: String.t() | nil,
          base_url: String.t(),
          plug: term() | nil
        }

  defstruct api_key: nil,
            base_url: @default_base_url,
            plug: nil

  @doc """
  Builds a client from a Kit v4 API key.

  Options:

    * `:base_url` — override the API base URL (defaults to
      `#{@default_base_url}`).
    * `:plug` — a `Req.Test` stub (e.g. `{Req.Test, MyStub}`) used to intercept
      requests in tests.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(api_key, opts \\ []) when is_binary(api_key) do
    %__MODULE__{
      api_key: api_key,
      base_url: Keyword.get(opts, :base_url, @default_base_url),
      plug: Keyword.get(opts, :plug)
    }
  end
end
