defmodule ExKitTest do
  use ExUnit.Case, async: true

  alias ExKit.Fixtures

  @stub __MODULE__.Stub

  test "new/2 builds a client with defaults" do
    client = ExKit.new("abc")
    assert client.api_key == "abc"
    assert client.base_url == "https://api.kit.com/v4"
    assert client.plug == nil
  end

  test "new/2 honors :base_url and :plug overrides" do
    client = ExKit.new("abc", base_url: "https://example.test/v4", plug: {Req.Test, @stub})
    assert client.base_url == "https://example.test/v4"
    assert client.plug == {Req.Test, @stub}
  end

  test "delegates create_subscriber to ExKit.Subscribers" do
    Req.Test.stub(@stub, fn conn ->
      assert conn.request_path == "/v4/subscribers"
      Req.Test.json(conn, Fixtures.subscriber())
    end)

    assert {:ok, %{"subscriber" => _}} =
             ExKit.create_subscriber(Fixtures.client(@stub), "alice@example.com")
  end
end
