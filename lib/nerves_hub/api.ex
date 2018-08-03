defmodule NervesHub.API do
  @host "api.nerves-hub.org"
  @config [
    host: @host,
    port: 443,
    ssl: [
      keyfile: "user-key.pem",
      certfile: "user.pem",
      cacertfile: "ca.pem",
      server_name_indication: to_charlist(@host)
    ]
  ]

  def start_pool() do
    pool = :nerves_hub
    pool_opts = [timeout: 150_000, max_connections: 10]
    :ok = :hackney_pool.start_pool(pool, pool_opts)
  end

  def request(_verb, _path, _body_or_params \\ "")

  def request(:get, path, params) do
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

  defp resp(resp) do
    {:error, resp}
  end

  defp url(path) do
    endpoint() <> path
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

  defp opts do
    [
      pool: :nerves_hub,
      ssl_options: Keyword.get(config(), :ssl, [])
    ]
  end

  defp config do
    Application.get_env(:nerves_hub, __MODULE__) || @config
  end
end
