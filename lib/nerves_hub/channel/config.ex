defmodule NervesHub.Channel.Config do
  alias NervesHub.Certificate

  @moduledoc false
  @runtime Application.get_env(:nerves_hub, :runtime)

  @channel_opts [:device_host, :device_port, :cacerts, :server_name_indication]

  @doc """
  This function derives additional options to control the Phoenix Channel Socket
  that may or may not have been specified by the user.
  """
  @spec derive_unspecified_options(keyword()) :: keyword()
  def derive_unspecified_options(opts) when is_list(opts) do
    user_config =
      Application.get_all_env(:nerves_hub)
      |> Enum.filter(fn {key, _} -> key in @channel_opts end)
      |> Keyword.merge(opts)

    ca_certs = user_config[:cacerts] || Certificate.ca_certs()

    {cert_key, cert_value} = cert(user_config)
    {key_key, key_value} = key(user_config)

    socket_opts =
      [
        cacerts: ca_certs,
        server_name_indication: sni(user_config)
      ]
      |> Keyword.put(cert_key, cert_value)
      |> Keyword.put(key_key, key_value)

    default_config = [
      url: endpoint(user_config),
      serializer: Jason,
      ssl_verify: :verify_peer,
      socket_opts: socket_opts
    ]

    Keyword.merge(default_config, user_config)
  end

  defp cert(opts) do
    cond do
      opts[:certfile] != nil -> {:certfile, opts[:certfile]}
      opts[:cert] != nil -> {:cert, opts[:cert]}
      true -> {:cert, @runtime.device_cert()}
    end
  end

  defp key(opts) do
    cond do
      opts[:keyfile] != nil ->
        {:keyfile, opts[:keyfile]}

      opts[:key] != nil ->
        {:key, opts[:key]}

      true ->
        {:key, @runtime.device_key()}
    end
  end

  defp sni(opts) do
    case opts[:server_name_indication] do
      nil -> to_charlist(opts[:device_host])
      false -> false
      other -> to_charlist(other)
    end
  end

  defp endpoint(opts) do
    %URI{
      scheme: "wss",
      host: opts[:device_host],
      port: opts[:device_port],
      path: "/socket/websocket"
    }
    |> URI.to_string()
  end
end
