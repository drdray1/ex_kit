defmodule ExKit.Fixtures do
  @moduledoc """
  Test fixtures and helpers for ExKit.
  """

  @doc "A client wired to a `Req.Test` stub."
  def client(stub_name) do
    ExKit.new(api_key(), plug: {Req.Test, stub_name})
  end

  @doc "The API key a `client/1` stub receives, for header assertions."
  def api_key, do: "test-api-key"

  @doc "A canned Kit `subscriber` response body."
  def subscriber(overrides \\ %{}) do
    subscriber =
      Map.merge(
        %{
          "id" => 349,
          "first_name" => "Alice",
          "email_address" => "alice@example.com",
          "state" => "active",
          "created_at" => "2023-02-17T11:43:55Z",
          "fields" => %{}
        },
        overrides
      )

    %{"subscriber" => subscriber}
  end

  @doc "Reads and decodes a request `Plug.Conn`'s JSON body."
  def read_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    Jason.decode!(body)
  end
end
