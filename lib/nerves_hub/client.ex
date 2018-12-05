defmodule NervesHub.Client do
  @moduledoc """
  Responsible for determining if an update should be applied.
  """
  require Logger

  @typedoc "Update that comes over a socket."
  @type update_data :: map()

  @doc """
  Called before an update is downloaded and applied. May return one of:
  * `apply` - Download and apply the update right now.
  * `ignore` - Don't download this update now or ever.
  * `{:reschedule, timeout} -> Don't donload the update. Call this function again
    in `timeout` milliseconds.
  """
  @callback update_available(update_data) :: :apply | :ignore | {:reschedule, pos_integer()}

  @type fwup_message ::
          {:ok, pos_integer, String.t()}
          | {:warning, pos_integer, String.t()}
          | {:error, pos_integer, String.t()}
          | {:progress, 0..100}

  @doc """
  Called whenever a message comes from a FWUP stream.
  The return value of this function is not checked.
  """
  @callback handle_fwup_message(fwup_message) :: :ok

  @doc """
  Called whenever a stream fails or exits for a non-normal reason.
  The return value of this function is not checked.
  """
  @callback handle_error(any) :: :ok

  def update_available(client, data) do
    case apply_wrap(client, :update_available, [data]) do
      :apply ->
        :apply

      :ignore ->
        :ignore

      {:reschedule, timeout} when timeout > 0 ->
        {:reschedule, timeout}

      wrong ->
        Logger.error(
          "[NervesHub] Client: #{client}.update_available/1 bad return value: #{inspect(wrong)} Applying update."
        )

        :apply
    end
  end

  def handle_fwup_message(client, data) do
    _ = apply_wrap(client, :handle_fwup_message, [data])
    :ok
  end

  def handle_error(client, data) do
    _ = apply_wrap(client, :handle_error, [data])
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
