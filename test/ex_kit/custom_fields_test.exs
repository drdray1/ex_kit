defmodule ExKit.CustomFieldsTest do
  use ExUnit.Case, async: true

  alias ExKit.{CustomFields, Fixtures}

  @stub __MODULE__.Stub

  describe "list_custom_fields/2" do
    test "GETs /custom_fields with pagination params" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v4/custom_fields"
        assert URI.decode_query(conn.query_string) == %{"per_page" => "100"}

        Req.Test.json(
          conn,
          Fixtures.page("custom_fields", [
            %{"id" => 1, "name" => "ck_field_1_phone", "key" => "phone", "label" => "Phone"}
          ])
        )
      end)

      assert {:ok, %{"custom_fields" => [%{"key" => "phone"}]}} =
               CustomFields.list_custom_fields(Fixtures.client(@stub), per_page: 100)
    end
  end

  describe "create_custom_field/2" do
    test "POSTs /custom_fields with the label" do
      Req.Test.stub(@stub, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v4/custom_fields"
        assert Fixtures.read_body(conn) == %{"label" => "Interests"}

        conn
        |> Plug.Conn.put_status(201)
        |> Req.Test.json(%{
          "custom_field" => %{
            "id" => 6,
            "name" => "ck_field_6_interests",
            "key" => "interests",
            "label" => "Interests"
          }
        })
      end)

      assert {:ok, %{"custom_field" => %{"key" => "interests"}}} =
               CustomFields.create_custom_field(Fixtures.client(@stub), "Interests")
    end
  end
end
