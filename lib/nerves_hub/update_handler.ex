defmodule NervesHub.UpdateHandler do
  @moduledoc """
  Responsible for determining if an update should be applied.
  """
  require Logger
  
  @typedoc "Update that comes over a socket."
  @type update_data :: map()

  @callback should_update?(update_data()) :: boolean()
  @callback update_frequency() :: pos_integer()

  @doc "Returns a boolean to determine if an update should be applied."
  @spec should_update?(module, update_data) :: boolean()
  def should_update?(handler, update) do
    case apply(handler, :should_update?, [update]) do
      b when is_boolean(b) -> b
      bad ->
        Logger.error "[NervesHub] #{handler} Not updating. bad return: #{inspect bad}."
        false      
    end
  end

  @doc "Returns a timeout in milliseconds for when an update should be rescheduled."
  @spec update_frequency(module) :: false | pos_integer()
  def update_frequency(handler) do
    case apply(handler, :update_frequency, []) do
      freq when freq > 0 -> freq
      bad ->
        Logger.error "[NervesHub] #{handler} not rescheduling update. bad return: #{inspect bad}" 
        false
    end
  end
end