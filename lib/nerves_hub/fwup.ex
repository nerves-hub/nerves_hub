defmodule NervesHub.Fwup do
  use GenServer
  require Logger

  @moduledoc """
  """

  def start_link(cm) do
    GenServer.start_link(__MODULE__, [cm])
  end

  def send_chunk(pid, chunk) do
    GenServer.call(pid, {:send, chunk})
  end

  def init([cm]) do
    fwup = System.find_executable("fwup")
    devpath = Nerves.Runtime.KV.get("nerves_fw_devpath") || "/dev/mmcblk0"
    task = "upgrade"
    args = ["-n", "--apply", "--no-unmount", "-d", devpath, "--task", task, "--exit-handshake"]
    fw_config = Application.get_env(:nerves_system_test, :firmware)

    args =
      if public_key = fw_config[:public_key] do
        args ++ ["--public-key", public_key]
      else
        args
      end

    port =
      Port.open(
        {:spawn_executable, fwup},
        [{:args, args}, :use_stdio, :binary, :exit_status]
      )

    {:ok, %{port: port, cm: cm}}
  end

  def handle_call({:send, chunk}, _from, state) do
    true = Port.command(state.port, chunk)
    {:reply, :ok, state}
  end

  def handle_info({port, {:data, response}}, %{port: port} = state) do
    trimmed_response =
      if String.contains?(response, "\x1a") do
        # fwup says that it's going to exit by sending a CTRL+Z (0x1a)
        # The CTRL+Z is the very last character that will ever be
        # received over the port, so handshake by closing the port.
        send(port, {self(), :close})
        String.trim_trailing(response, "\x1a")
      else
        response
      end

    Logger.debug(trimmed_response)
    {:noreply, state}
  end

  def handle_info({_port, {:exit_status, status}}, state) do
    Logger.info("fwup exited with status #{status}")
    send(state.cm, {:fwup, :done})
    {:noreply, state}
  end
end
