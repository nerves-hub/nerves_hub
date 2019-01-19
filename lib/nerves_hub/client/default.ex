defmodule NervesHub.Client.Default do
  @moduledoc """
  Default NervesHub.Client implementation

  This client always accepts an update.
  """

  @behaviour NervesHub.Client
  require Logger

  @impl NervesHub.Client
  def update_available(_), do: :apply

  @impl NervesHub.Client
  def handle_fwup_message({:progress, percent}) when rem(percent, 25) == 0 do
    Logger.debug("FWUP PROG: #{percent}%")
  end

  def handle_fwup_message({:error, _, message}) do
    Logger.error("FWUP ERROR: #{message}")
  end

  def handle_fwup_message({:warning, _, message}) do
    Logger.warn("FWUP WARN: #{message}")
  end

  def handle_fwup_message(_fwup_message) do
    :ok
  end

  @impl NervesHub.Client
  def handle_error(error) do
    Logger.warn("Firmware stream error: #{inspect(error)}")
  end
end
