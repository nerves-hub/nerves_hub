defmodule NervesHub.Client do
  @moduledoc """
  Responsible for determining if an update should be applied.
  """
  require Logger

  @typedoc "Update that comes over a socket."
  @type update_data :: map()

  @callback update_available(update_data) :: :apply | :ignore | {:reschedule, pos_integer()}

  @callback reboot_required() :: :apply | :ignore | {:reschedule, pos_integer()}

  def update_available(client, data) do
    case apply_wrap(client, :update_available, [data]) do
      :apply ->
        :apply

      :ignore ->
        :ignore

      {:reschedule, timeout} when timeout > 0 ->
        {:reschedule, timeout}

      wrong ->
        Logger.error("[NervesHub] Client bad return value: #{inspect(wrong)} Applying update.")
        :apply
    end
  end

  def reboot_required(client) do
    case apply_wrap(client, :reboot_required) do
      :apply ->
        :apply

      :ignore ->
        :ignore

      {:reschedule, timeout} when timeout > 0 ->
        {:reschedule, timeout}

      wrong ->
        Logger.error("[NervesHub] Client bad return value: #{inspect(wrong)} Rebooting")
        :apply
    end
  end

  # Catches exceptions and exits
  def apply_wrap(client, function, args \\ []) do
    apply(client, function, args)
  catch
    :error, reason -> {:error, reason}
    :exit, reason -> {:exit, reason}
    err -> err
  end
end
