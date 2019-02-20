defmodule NervesHub.Supervisor do
  use Supervisor

  alias NervesHub.Channel
  alias PhoenixClient.Socket

  @moduledoc """
  Supervisor for maintaining a channel connection to a NervesHub server

  This module starts the GenServers that maintain a Phoenix channel connection
  to the NervesHub server and respond to update requests.  It isn't started
  automatically, so you should add it to one of your OTP application's
  supervision trees:

  ```elixir
    defmodule Example.Application do
      use Application

      def start(_type, _args) do

        opts = [strategy: :one_for_one, name: Example.Supervisor]
        children = [
          NervesHub.Supervisor
        ] ++ children(@target)
        Supervisor.start_link(children, opts)
      end
    end
  ```
  """

  @doc """
  Start the NervesHub supervision tree
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(socket_opts) do
    Supervisor.start_link(__MODULE__, socket_opts, name: __MODULE__)
  end

  @impl true
  def init(socket_opts) do
    socket_opts =
      Application.get_env(:nerves_hub, :socket, [])
      |> Keyword.merge(socket_opts)
      |> NervesHub.Socket.opts()

    children = [
      {Socket, {socket_opts, [name: Socket]}},
      {Channel, [socket: Socket, topic: "device"]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
