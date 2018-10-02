defmodule NervesHub.Client.Default do
  @moduledoc """
  Default Client implementation.
  Always applies an update. Never Reschedules
  """

  @behaviour NervesHub.Client

  @impl NervesHub.Client
  def update_available(_), do: :apply
end
