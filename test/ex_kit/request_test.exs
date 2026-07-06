defmodule ExKit.RequestTest do
  use ExUnit.Case, async: true

  alias ExKit.{Fixtures, Request}

  @stub __MODULE__.Stub

  describe "handle_response via request/4" do
    test "200/201/202 return {:ok, body}" do
      for status <- [200, 201, 202] do
        Req.Test.stub(@stub, fn conn ->
          conn
          |> Plug.Conn.put_status(status)
          |> Req.Test.json(%{"ok" => status})
        end)

        assert {:ok, %{"ok" => ^status}} =
                 Request.request(Fixtures.client(@stub), :post, "/subscribers", json: %{})
      end
    end

    test "401 and 403 map to :unauthorized" do
      for status <- [401, 403] do
        Req.Test.stub(@stub, fn conn -> Plug.Conn.send_resp(conn, status, "") end)

        assert {:error, :unauthorized} =
                 Request.request(Fixtures.client(@stub), :get, "/subscribers")
      end
    end

    test "404 maps to :not_found" do
      Req.Test.stub(@stub, fn conn -> Plug.Conn.send_resp(conn, 404, "") end)
      assert {:error, :not_found} = Request.request(Fixtures.client(@stub), :get, "/x")
    end

    test "422 maps to {:unprocessable, body}" do
      Req.Test.stub(@stub, fn conn ->
        conn
        |> Plug.Conn.put_status(422)
        |> Req.Test.json(%{"errors" => ["email is invalid"]})
      end)

      assert {:error, {:unprocessable, %{"errors" => ["email is invalid"]}}} =
               Request.request(Fixtures.client(@stub), :post, "/subscribers", json: %{})
    end

    test "429 maps to :rate_limited" do
      Req.Test.stub(@stub, fn conn -> Plug.Conn.send_resp(conn, 429, "") end)
      assert {:error, :rate_limited} = Request.request(Fixtures.client(@stub), :get, "/x")
    end

    test "other >= 400 maps to {:unexpected_status, status}" do
      Req.Test.stub(@stub, fn conn -> Plug.Conn.send_resp(conn, 500, "") end)

      assert {:error, {:unexpected_status, 500}} =
               Request.request(Fixtures.client(@stub), :get, "/x")
    end

    test "a transport error maps to {:connection_error, reason}" do
      Req.Test.stub(@stub, fn conn -> Req.Test.transport_error(conn, :econnrefused) end)

      assert {:error, {:connection_error, %Req.TransportError{reason: :econnrefused}}} =
               Request.request(Fixtures.client(@stub), :get, "/x")
    end
  end
end
