defmodule NervesHub.HTTPClient do
  @host "device.nerves-hub.org"
  @port 443
  @cert "nerves_hub_cert"
  @key "nerves_hub_key"

  alias NervesHub.Certificate

  def me do
    request(:get, "/device/me", [])
  end

  def update do
    request(:get, "/device/update", [])
  end

  def request(:get, path, params) when is_map(params) do
    url = url(path) <> "?" <> URI.encode_query(params)

    :hackney.request(:get, url, headers(), "", opts())
    |> resp()
  end

  def request(verb, path, params) when is_map(params) do
    with {:ok, body} <- Jason.encode(params) do
      request(verb, path, body)
    end
  end

  def request(verb, path, body) do
    :hackney.request(verb, url(path), headers(), body, opts())
    |> resp()
  end

  def file_request(verb, path, file) do
    :hackney.request(verb, url(path), [], {:file, file}, opts())
    |> resp()
  end

  defp resp({:ok, status_code, _headers, client_ref})
       when status_code >= 200 and status_code < 300 do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:ok, ""}

      {:ok, body} ->
        Jason.decode(body)

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp({:ok, _status_code, _headers, client_ref}) do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:error, ""}

      {:ok, body} ->
        resp =
          case Jason.decode(body) do
            {:ok, body} -> body
            body -> body
          end

        {:error, resp}

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp(resp) do
    {:error, resp}
  end

  defp url(path) do
    endpoint() <> path
  end

  defp opts() do
    ssl_options =
      ssl_options()
      |> Keyword.put(:cacerts, Certificate.ca_certs())

    [
      ssl_options: ssl_options,
      recv_timeout: 60_000
    ]
  end

  defp ssl_options() do
    cert = Nerves.Runtime.KV.get(@cert) |> Certificate.pem_to_der()
    key = Nerves.Runtime.KV.get(@key) |> Certificate.pem_to_der()

    [
      key: {:ECPrivateKey, key},
      cert: cert,
      server_name_indication: to_charlist(@host)
    ]
  end

  defp endpoint do
    config = config()
    host = config[:host]
    port = config[:port]
    "https://#{host}:#{port}/"
  end

  defp headers do
    [{"Content-Type", "application/json"}]
  end

  defp config do
    Application.get_env(:nerves_hub, __MODULE__) ||
      [
        host: @host,
        port: @port
      ]
  end
end
