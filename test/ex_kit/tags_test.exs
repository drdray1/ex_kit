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

    test "includes a referrer when given" do
      Req.Test.stub(@stub, fn conn ->
        assert Fixtures.read_body(conn) == %{
                 "email_address" => "alice@example.com",
                 "referrer" => "https://capitalwesthomes.com/contact"
               }

        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, _} =
               Tags.tag_subscriber(Fixtures.client(@stub), 207, "alice@example.com",
                 referrer: "https://capitalwesthomes.com/contact"
               )
    end
  end

  describe "untag_subscriber/3" do
    test "DELETEs /tags/:id/subscribers with the email as a query param" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/tags/207/subscribers"
        assert URI.decode_query(conn.query_string) == %{"email_address" => "alice@example.com"}
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} =
               Tags.untag_subscriber(Fixtures.client(@stub), 207, "alice@example.com")
    end
  end

  describe "untag_subscriber_by_id/3" do
    test "DELETEs /tags/:id/subscribers/:subscriber_id" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v4/tags/207/subscribers/349"
        assert conn.query_string == ""
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, %{}} = Tags.untag_subscriber_by_id(Fixtures.client(@stub), 207, 349)
    end
  end

  describe "list_tags/2" do
    test "GETs /tags with no params by default" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/tags"
        assert conn.query_string == ""
        Req.Test.json(conn, Fixtures.page("tags", [%{"id" => 11, "name" => "Website Lead"}]))
      end)

      assert {:ok, %{"tags" => [%{"id" => 11, "name" => "Website Lead"}], "pagination" => _}} =
               Tags.list_tags(Fixtures.client(@stub))
    end

    test "passes pagination/include params, dropping unknown or nil options" do
      Req.Test.stub(@stub, fn conn ->
        assert URI.decode_query(conn.query_string) == %{
                 "after" => "MTE=",
                 "per_page" => "10",
                 "include" => "subscriber_count"
               }

        Req.Test.json(conn, Fixtures.page("tags", []))
      end)

      assert {:ok, _} =
               Tags.list_tags(Fixtures.client(@stub),
                 after: "MTE=",
                 per_page: 10,
                 include: "subscriber_count",
                 before: nil,
                 bogus: "dropped"
               )
    end
  end

  describe "create_tag/2" do
    test "POSTs /tags with the name" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/tags"
        assert Fixtures.read_body(conn) == %{"name" => "Website Lead"}

        conn
        |> Plug.Conn.put_status(201)
        |> Req.Test.json(%{"tag" => %{"id" => 25, "name" => "Website Lead"}})
      end)

      assert {:ok, %{"tag" => %{"id" => 25}}} =
               Tags.create_tag(Fixtures.client(@stub), "Website Lead")
    end
  end
end
