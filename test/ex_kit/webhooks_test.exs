defmodule ExKit.WebhooksTest do
  use ExUnit.Case, async: true

  alias ExKit.{Fixtures, Webhooks}

  @stub __MODULE__.Stub

  describe "list_webhooks/2" do
    test "GETs /webhooks with no params by default" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/webhooks"
        assert conn.query_string == ""
        Req.Test.json(conn, Fixtures.page("webhooks", [%{"id" => 9}]))
      end)

      assert {:ok, %{"webhooks" => [%{"id" => 9}], "pagination" => _}} =
               Webhooks.list_webhooks(Fixtures.client(@stub))
    end

    test "passes pagination params, dropping unknown or nil options" do
      Req.Test.stub(@stub, fn conn ->
        assert URI.decode_query(conn.query_string) == %{"per_page" => "10"}
        Req.Test.json(conn, Fixtures.page("webhooks", []))
      end)

      assert {:ok, _} =
               Webhooks.list_webhooks(Fixtures.client(@stub),
                 per_page: 10,
                 before: nil,
                 bogus: "dropped"
               )
    end
  end

  describe "create_webhook/3" do
    test "POSTs /webhooks with the target_url and event map" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/webhooks"

        assert Fixtures.read_body(conn) == %{
                 "target_url" => "https://example.com/hook",
                 "event" => %{"name" => "subscriber.form_subscribe", "form_id" => 1}
               }

        conn
        |> Plug.Conn.put_status(201)
        |> Req.Test.json(%{
          "webhook" => %{"id" => 9, "target_url" => "https://example.com/hook"}
        })
      end)

      assert {:ok, %{"webhook" => %{"id" => 9}}} =
               Webhooks.create_webhook(
                 Fixtures.client(@stub),
                 "https://example.com/hook",
                 %{name: "subscriber.form_subscribe", form_id: 1}
               )
    end
  end

  describe "delete_webhook/2" do
    test "DELETEs /webhooks/:id, returning {:ok, %{}} on 204" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/webhooks/9"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = Webhooks.delete_webhook(Fixtures.client(@stub), 9)
    end
  end
end
