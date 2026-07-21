defmodule ExKit.SubscribersTest do
  use ExUnit.Case, async: true

  alias ExKit.{Fixtures, Subscribers}

  @stub __MODULE__.Stub

  describe "create_subscriber/3" do
    test "POSTs /subscribers with the api key and email, returning the body" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/subscribers"
        assert Plug.Conn.get_req_header(conn, "x-kit-api-key") == [Fixtures.api_key()]
        assert Fixtures.read_body(conn) == %{"email_address" => "alice@example.com"}

        conn
        |> Plug.Conn.put_status(201)
        |> Req.Test.json(Fixtures.subscriber())
      end)

      assert {:ok, %{"subscriber" => %{"email_address" => "alice@example.com"}}} =
               Subscribers.create_subscriber(Fixtures.client(@stub), "alice@example.com")
    end

    test "includes optional first_name, state, and fields when given" do
      Req.Test.stub(@stub, fn conn ->
        assert Fixtures.read_body(conn) == %{
                 "email_address" => "alice@example.com",
                 "first_name" => "Alice",
                 "state" => "active",
                 "fields" => %{"company" => "CWH"}
               }

        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, _} =
               Subscribers.create_subscriber(Fixtures.client(@stub), "alice@example.com",
                 first_name: "Alice",
                 state: "active",
                 fields: %{"company" => "CWH"}
               )
    end

    test "omits optional fields that are nil" do
      Req.Test.stub(@stub, fn conn ->
        assert Fixtures.read_body(conn) == %{"email_address" => "alice@example.com"}
        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, _} =
               Subscribers.create_subscriber(Fixtures.client(@stub), "alice@example.com",
                 first_name: nil
               )
    end
  end

  describe "get_subscriber/2" do
    test "GETs /subscribers/:id" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/subscribers/349"
        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, %{"subscriber" => %{"id" => 349}}} =
               Subscribers.get_subscriber(Fixtures.client(@stub), 349)
    end
  end

  describe "list_subscribers/2" do
    test "GETs /subscribers with no params by default" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/subscribers"
        assert conn.query_string == ""
        Req.Test.json(conn, Fixtures.page("subscribers", [%{"id" => 349}]))
      end)

      assert {:ok, %{"subscribers" => [%{"id" => 349}], "pagination" => _}} =
               Subscribers.list_subscribers(Fixtures.client(@stub))
    end

    test "passes filter/pagination params, dropping unknown or nil options" do
      Req.Test.stub(@stub, fn conn ->
        assert URI.decode_query(conn.query_string) == %{
                 "status" => "active",
                 "email_address" => "alice@example.com",
                 "per_page" => "10"
               }

        Req.Test.json(conn, Fixtures.page("subscribers", []))
      end)

      assert {:ok, _} =
               Subscribers.list_subscribers(Fixtures.client(@stub),
                 status: "active",
                 email_address: "alice@example.com",
                 per_page: 10,
                 before: nil,
                 bogus: "dropped"
               )
    end
  end

  describe "list_subscriber_tags/3" do
    test "GETs /subscribers/:id/tags" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/subscribers/349/tags"
        Req.Test.json(conn, Fixtures.page("tags", [%{"id" => 11, "name" => "Website Lead"}]))
      end)

      assert {:ok, %{"tags" => [%{"id" => 11}], "pagination" => _}} =
               Subscribers.list_subscriber_tags(Fixtures.client(@stub), 349)
    end
  end

  describe "unsubscribe/2" do
    test "POSTs /subscribers/:id/unsubscribe, returning {:ok, %{}} on 204" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/subscribers/349/unsubscribe"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = Subscribers.unsubscribe(Fixtures.client(@stub), 349)
    end
  end
end
