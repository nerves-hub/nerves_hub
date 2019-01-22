defmodule NervesHub.HTTPClient do
  @moduledoc false

  alias NervesHub.Certificate

  @type method :: :get | :put | :post
  @type url :: binary()
  @type header :: {binary(), binary()}
  @type body :: binary()
  @type opts :: keyword()

  @callback request(method(), url(), [header()], body(), opts()) :: {:ok, %{}} | {:error, any()}

  @host "device.nerves-hub.org"
  @client Application.get_env(:nerves_hub, :http_client, NervesHub.HTTPClient.Default)

  def me, do: request(:get, "/device/me", [])

  def update, do: request(:get, "/device/update", [])

  def request(:get, path, params) when is_map(params) do
    url = url(path) <> "?" <> URI.encode_query(params)
    @client.request(:get, url, headers(), [], opts())
  end

  def request(verb, path, params) when is_map(params) do
    with {:ok, body} <- Jason.encode(params) do
      request(verb, path, body)
    end
  end

  def request(verb, path, body) do
    @client.request(verb, url(path), headers(), body, opts())
  end

  def url(path), do: endpoint() <> path

  defp opts() do
    [
      ssl_options: ssl_options(),
      recv_timeout: 60_000
    ]
  end

  defp ssl_options() do
    [
      cacerts: Certificate.ca_certs(),
      cert: NervesHub.Runtime.device_cert(),
      key: NervesHub.Runtime.device_key(),
      server_name_indication: to_charlist(@host)
    ]
  end

  defp endpoint() do
    host = Application.get_env(:nerves_hub, :device_host)
    port = Application.get_env(:nerves_hub, :device_port)
    "https://#{host}:#{port}"
  end

  defp headers() do
    [
      {"Content-Type", "application/json"},
      {"X-NervesHub-Dn", NervesHub.Runtime.serial_number()},
      {"X-NervesHub-Uuid", NervesHub.Runtime.running_firmware_uuid()}
    ]
  end
end
