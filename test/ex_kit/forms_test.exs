defmodule ExKit.FormsTest do
  use ExUnit.Case, async: true

  alias ExKit.{Forms, Fixtures}

  @stub __MODULE__.Stub

  describe "add_subscriber_to_form/4" do
    test "POSTs /forms/:id/subscribers with the email" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/forms/234/subscribers"
        assert Fixtures.read_body(conn) == %{"email_address" => "alice@example.com"}
        Req.Test.json(conn, Fixtures.subscriber())
      end)

      assert {:ok, %{"subscriber" => _}} =
               Forms.add_subscriber_to_form(Fixtures.client(@stub), 234, "alice@example.com")
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
               Forms.add_subscriber_to_form(Fixtures.client(@stub), "234", "alice@example.com",
                 referrer: "https://capitalwesthomes.com/contact"
               )
    end
  end
end
