defmodule NervesHub.Supervisor do
  use Supervisor

  alias NervesHub.{Socket, FirmwareChannel}

  def start_link(socket_opts) do
    case Supervisor.start_link(__MODULE__, socket_opts, name: __MODULE__) do
      {:ok, pid} ->
        NervesHub.connect()
        {:ok, pid}

      error ->
        error
    end
  end

  @impl true
  def init(socket_opts) do
    socket_opts =
      Application.get_env(:nerves_hub, Socket, [])
      |> Keyword.merge(socket_opts)
      |> Socket.opts()

    children = [
      {Socket, socket_opts},
      {FirmwareChannel,
       {[socket: Socket, topic: FirmwareChannel.topic()], [name: FirmwareChannel]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
