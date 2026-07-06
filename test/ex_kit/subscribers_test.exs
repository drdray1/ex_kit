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
end
