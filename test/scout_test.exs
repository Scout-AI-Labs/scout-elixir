defmodule ScoutTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()

    client =
      Scout.new(
        api_key: "sk_live_xyz",
        base_url: "http://localhost:#{bypass.port}",
        max_retries: 3
      )

    {:ok, bypass: bypass, client: client}
  end

  test "POST round-trip sends auth + idempotency and echoes the body", %{
    bypass: bypass,
    client: client
  } do
    Bypass.expect_once(bypass, "POST", "/v1/search", fn conn ->
      {:ok, raw, conn} = Plug.Conn.read_body(conn)
      parsed = Jason.decode!(raw)

      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer sk_live_xyz"]
      assert [idem] = Plug.Conn.get_req_header(conn, "idempotency-key")
      assert idem != ""
      assert parsed["depth"] == "standard"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.put_resp_header("x-request-id", "req_abc123")
      |> Plug.Conn.resp(200, Jason.encode!(%{"ok" => true, "echo" => parsed}))
    end)

    assert {:ok, %{"ok" => true, "echo" => %{"depth" => "standard"}}} =
             Scout.Search.create(client, %{queries: ["hello world"], depth: "standard"})
  end

  test "GET list encodes query params", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "GET", "/v1/searches", fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      assert conn.query_params["limit"] == "5"

      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"items" => [%{"id" => 1}]}))
    end)

    assert {:ok, %{"items" => [%{"id" => 1}]}} = Scout.Search.list(client, limit: 5)
  end

  test "retries on 500 then succeeds", %{bypass: bypass, client: client} do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    Bypass.expect(bypass, "POST", "/v1/site/map", fn conn ->
      n = Agent.get_and_update(counter, fn c -> {c + 1, c + 1} end)

      conn = Plug.Conn.put_resp_header(conn, "content-type", "application/json")

      if n < 3 do
        Plug.Conn.resp(conn, 500, Jason.encode!(%{"detail" => "transient"}))
      else
        Plug.Conn.resp(conn, 200, Jason.encode!(%{"ok" => true, "tries" => n}))
      end
    end)

    assert {:ok, %{"ok" => true, "tries" => 3}} =
             Scout.Site.map(client, %{start_url: "https://example.com"})
  end

  test "maps 401 to a typed error with request id", %{bypass: bypass, client: client} do
    Bypass.expect_once(bypass, "POST", "/v1/company", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("content-type", "application/json")
      |> Plug.Conn.put_resp_header("x-request-id", "req_abc123")
      |> Plug.Conn.resp(401, Jason.encode!(%{"detail" => "invalid api key"}))
    end)

    assert {:error, %Scout.Error{} = error} = Scout.Company.enrich(client, %{domain: "x.com"})
    assert error.status == 401
    assert error.request_id == "req_abc123"
    assert error.message == "invalid api key"
    assert Scout.Error.authentication?(error)
  end

  test "missing API key raises", _ctx do
    assert_raise Scout.Error, fn -> Scout.new(api_key: "") end
  end

  test "extract_items pulls the array from a list response" do
    assert Scout.Pagination.extract_items(%{"items" => [1, 2, 3]}) == [1, 2, 3]
    assert Scout.Pagination.extract_items([1, 2]) == [1, 2]
    assert Scout.Pagination.extract_items(%{"x" => 1}) == []
  end
end
