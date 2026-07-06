defmodule ExKit.TagsTest do
  use ExUnit.Case, async: true

  alias ExKit.{Fixtures, Tags}

  @stub __MODULE__.Stub

  describe "tag_subscriber/4" do
    test "POSTs /tags/:id/subscribers with the email" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/tags/207/subscribers"
        assert Fixtures.read_body(conn) == %{"email_address" => "alice@example.com"}
        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, %{"subscriber" => _}} =
               Tags.tag_subscriber(Fixtures.client(@stub), 207, "alice@example.com")
    end
  end
end
