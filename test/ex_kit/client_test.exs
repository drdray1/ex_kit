defmodule ExKit.ClientTest do
  use ExUnit.Case, async: true

  alias ExKit.Client

  describe "new/2" do
    # Called with a single argument so the arity-1 default-head clause is
    # exercised (delegation from `ExKit.new/1` calls the arity-2 clause directly
    # and would otherwise leave this head uncovered).
    test "new/1 uses the default base_url and no plug" do
      client = Client.new("kit_v4_api_key")
      assert %Client{api_key: "kit_v4_api_key", plug: nil} = client
      assert client.base_url == "https://api.kit.com/v4"
    end

    test "new/2 honors :base_url and :plug overrides" do
      client = Client.new("k", base_url: "https://example.test/v4", plug: {Req.Test, :stub})
      assert client.base_url == "https://example.test/v4"
      assert client.plug == {Req.Test, :stub}
    end
  end
end
