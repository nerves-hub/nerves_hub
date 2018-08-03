defmodule Mix.NervesHub.Shell do
  def info(message) do
    Mix.shell().info(message)
  end

  def raise(message) do
    Mix.raise(message)
  end
end
