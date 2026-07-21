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

  # Each defdelegate is exercised here so the public `ExKit` facade — the
  # surface users actually call — is covered end to end. The stub asserts the
  # method + path so we also confirm each delegate targets the right endpoint.
  # No-opts arities are used where a delegate has a default argument so the
  # arity-n-1 clause is covered too.

  describe "subscriber delegates" do
    test "create_subscriber -> POST /subscribers" do
      expect("POST", "/v4/subscribers", Fixtures.subscriber())

      assert {:ok, %{"subscriber" => _}} =
               ExKit.create_subscriber(Fixtures.client(@stub), "alice@example.com")
    end

    test "get_subscriber -> GET /subscribers/:id" do
      expect("GET", "/v4/subscribers/349", Fixtures.subscriber())
      assert {:ok, %{"subscriber" => _}} = ExKit.get_subscriber(Fixtures.client(@stub), 349)
    end

    test "list_subscribers -> GET /subscribers" do
      expect("GET", "/v4/subscribers", Fixtures.page("subscribers", []))
      assert {:ok, %{"subscribers" => []}} = ExKit.list_subscribers(Fixtures.client(@stub))
    end

    test "list_subscriber_tags -> GET /subscribers/:id/tags" do
      expect("GET", "/v4/subscribers/349/tags", Fixtures.page("tags", []))

      assert {:ok, %{"tags" => []}} =
               ExKit.list_subscriber_tags(Fixtures.client(@stub), 349)
    end

    test "unsubscribe -> POST /subscribers/:id/unsubscribe" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/subscribers/349/unsubscribe"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = ExKit.unsubscribe(Fixtures.client(@stub), 349)
    end
  end

  describe "form delegates" do
    test "add_subscriber_to_form -> POST /forms/:id/subscribers" do
      expect("POST", "/v4/forms/234/subscribers", Fixtures.subscriber())

      assert {:ok, %{"subscriber" => _}} =
               ExKit.add_subscriber_to_form(Fixtures.client(@stub), 234, "alice@example.com")
    end

    test "list_forms -> GET /forms" do
      expect("GET", "/v4/forms", Fixtures.page("forms", []))
      assert {:ok, %{"forms" => []}} = ExKit.list_forms(Fixtures.client(@stub))
    end
  end

  describe "tag delegates" do
    test "tag_subscriber -> POST /tags/:id/subscribers" do
      expect("POST", "/v4/tags/207/subscribers", Fixtures.subscriber())

      assert {:ok, %{"subscriber" => _}} =
               ExKit.tag_subscriber(Fixtures.client(@stub), 207, "alice@example.com")
    end

    test "untag_subscriber -> DELETE /tags/:id/subscribers" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/tags/207/subscribers"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} =
               ExKit.untag_subscriber(Fixtures.client(@stub), 207, "alice@example.com")
    end

    test "untag_subscriber_by_id -> DELETE /tags/:id/subscribers/:subscriber_id" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/tags/207/subscribers/349"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = ExKit.untag_subscriber_by_id(Fixtures.client(@stub), 207, 349)
    end

    test "list_tags -> GET /tags" do
      expect("GET", "/v4/tags", Fixtures.page("tags", []))
      assert {:ok, %{"tags" => []}} = ExKit.list_tags(Fixtures.client(@stub))
    end

    test "create_tag -> POST /tags" do
      expect("POST", "/v4/tags", %{"tag" => %{"id" => 25}})
      assert {:ok, %{"tag" => _}} = ExKit.create_tag(Fixtures.client(@stub), "Website Lead")
    end
  end

  describe "custom field delegates" do
    test "list_custom_fields -> GET /custom_fields" do
      expect("GET", "/v4/custom_fields", Fixtures.page("custom_fields", []))

      assert {:ok, %{"custom_fields" => []}} =
               ExKit.list_custom_fields(Fixtures.client(@stub))
    end

    test "create_custom_field -> POST /custom_fields" do
      expect("POST", "/v4/custom_fields", %{"custom_field" => %{"id" => 6}})

      assert {:ok, %{"custom_field" => _}} =
               ExKit.create_custom_field(Fixtures.client(@stub), "Phone")
    end
  end

  describe "webhook delegates" do
    test "list_webhooks -> GET /webhooks" do
      expect("GET", "/v4/webhooks", Fixtures.page("webhooks", []))
      assert {:ok, %{"webhooks" => []}} = ExKit.list_webhooks(Fixtures.client(@stub))
    end

    test "create_webhook -> POST /webhooks" do
      expect("POST", "/v4/webhooks", %{"webhook" => %{"id" => 3}})

      assert {:ok, %{"webhook" => _}} =
               ExKit.create_webhook(Fixtures.client(@stub), "https://example.com/hook", %{
                 name: "subscriber.subscriber_unsubscribe"
               })
    end

    test "delete_webhook -> DELETE /webhooks/:id" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/webhooks/3"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = ExKit.delete_webhook(Fixtures.client(@stub), 3)
    end
  end

  # Stubs a single request, asserting its method + path and replying with `body`.
  defp expect(method, path, body) do
    Req.Test.stub(@stub, fn conn ->
      assert conn.method == method
      assert conn.request_path == path
      Req.Test.json(conn, body)
    end)
  end
end
