defmodule NervesHub.HTTPClient do
  @moduledoc false

  alias NervesHub.Certificate
  alias NervesHub.HTTPClient.Default

  @type method :: :get | :put | :post
  @type url :: binary()
  @type header :: {binary(), binary()}
  @type body :: binary()
  @type opts :: keyword()

  @callback request(method(), url(), [header()], body(), opts()) :: {:ok, %{}} | {:error, any()}

  @cert "nerves_hub_cert"
  @key "nerves_hub_key"
  @client Application.get_env(:nerves_hub, :http_client, Default)

  def me, do: request(:get, "/device/me", [])

  def update, do: request(:get, "/device/update", [])

  def request(:get, path, params) when is_map(params) do
    url = url(path) <> "?" <> URI.encode_query(params)

    @client.request(:get, url, headers(), [], opts())
    |> check_response()
  end

  def request(verb, path, params) when is_map(params) do
    with {:ok, body} <- Jason.encode(params) do
      request(verb, path, body)
    end
  end

  def request(verb, path, body) do
    @client.request(verb, url(path), headers(), body, opts())
    |> check_response()
  end

  def url(path), do: endpoint() <> path

  defp check_response(response) do
    case response do
      {:ok, _} ->
        NervesHub.Connection.connected()

      {:error, _} ->
        NervesHub.Connection.disconnected()

      _ ->
        raise(
          "invalid HTTP response. request/5 must return a tuple with {:ok, resp} or {:error, resp}"
        )
    end

    response
  end

  defp opts() do
    [
      ssl_options: ssl_options(),
      recv_timeout: 60_000
    ]
  end

  defp ssl_options() do
    cert = Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()

    key =
      with key when not is_nil(key) <- Nerves.Runtime.KV.get(@key) do
        case X509.PrivateKey.from_pem(key) do
          {:error, :not_found} -> <<>>
          {:ok, decoded} -> X509.PrivateKey.to_der(decoded)
        end
      else
        nil -> <<>>
      end

    sni = Application.get_env(:nerves_hub, :device_api_sni)

    [
      cacerts: Certificate.ca_certs(),
      cert: cert,
      key: {:ECPrivateKey, key},
      server_name_indication: to_charlist(sni)
    ]
  end

  defp endpoint do
    host = Application.get_env(:nerves_hub, :device_api_host)
    port = Application.get_env(:nerves_hub, :device_api_port)
    "https://#{host}:#{port}"
  end

  defp headers do
    headers = [{"Content-Type", "application/json"}]

    Nerves.Runtime.KV.get_all_active()
    |> Enum.reduce(headers, fn
      {"nerves_fw_" <> key, value}, headers ->
        [{"X-NervesHub-" <> key, value} | headers]

      _, headers ->
        headers
    end)
  end
end
