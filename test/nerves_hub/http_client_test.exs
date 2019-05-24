defmodule NervesHub.HTTPClientTest do
  use ExUnit.Case, async: true
  alias NervesHub.HTTPClient

  doctest HTTPClient

  setup context, do: Mox.verify_on_exit!(context)

  test "me/0" do
    url = HTTPClient.url("/device/me")

    Mox.expect(HTTPClient.Mock, :request, fn :get, ^url, _, _, _ ->
      {:ok, :response}
    end)

    assert HTTPClient.me() == {:ok, :response}
  end

  test "update/0" do
    url = HTTPClient.url("/device/update")

    Mox.expect(HTTPClient.Mock, :request, fn :get, ^url, _, _, _ ->
      {:ok, :response}
    end)

    assert HTTPClient.update() == {:ok, :response}
  end

  describe "request/3" do
    test ":get with params" do
      params = %{key: :val}
      url = "#{HTTPClient.url("/path")}?#{URI.encode_query(params)}"

      Mox.expect(HTTPClient.Mock, :request, fn :get, ^url, _, _, _ ->
        {:ok, :response}
      end)

      assert HTTPClient.request(:get, "/path", params) == {:ok, :response}
    end

    test "non :get with params" do
      params = %{key: :val}
      url = HTTPClient.url("/path")
      body = Jason.encode!(params)

      Mox.expect(HTTPClient.Mock, :request, fn :put, ^url, _, ^body, _ ->
        {:ok, :response}
      end)

      assert HTTPClient.request(:put, "/path", params) == {:ok, :response}
    end

    test "no params" do
      url = HTTPClient.url("/path")

      Mox.expect(HTTPClient.Mock, :request, fn :get, ^url, _, [], _ ->
        {:ok, :response}
      end)

      assert HTTPClient.request(:get, "/path", []) == {:ok, :response}
    end
  end

  test "url/1" do
    assert HTTPClient.url("/test/me") == "https://0.0.0.0:4001/test/me"
  end
end
