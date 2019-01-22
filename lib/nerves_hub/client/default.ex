defmodule NervesHub.Client.Default do
  @moduledoc """
  This is the default NervesHub.Client implementation.

  This client always accepts an update and logs notification.
  """

  @behaviour NervesHub.Client
  require Logger

  @impl true
  def update_available(_), do: :apply

  @impl true
  def handle_fwup_message({:progress, percent}) when rem(percent, 25) == 0 do
    Logger.debug("Firmware update progress: #{percent}%")
  end

  @impl true
  def handle_fwup_message({:error, _, message}) do
    Logger.error("Firmware update error: #{message}")
  end

  @impl true
  def handle_fwup_message({:warning, _, message}) do
    Logger.warn("Firmware update warning: #{message}")
  end

  @impl true
  def handle_fwup_message(_fwup_message) do
    # Ignore other reports
    :ok
  end

  @impl true
  def handle_error(error) do
    Logger.warn("Firmware stream error: #{inspect(error)}")
  end
end
