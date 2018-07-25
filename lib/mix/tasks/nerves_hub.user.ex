defmodule Mix.Tasks.NervesHub.User do
  use Mix.Task

  alias NervesHub.API

  @shortdoc "Manages your NervesHub user account"

  @switches [
    
  ]

  def run(args) do
    Application.ensure_all_started(:nerves_hub)

    {opts, args} = OptionParser.parse!(args, strict: @switches)
    
    case args do
      ["whoami"] ->
        whoami()
    end
  end

  def whoami do
    case API.User.me() do
      {:ok, %{"data" => data}} ->
        %{"name" => name, "email" => email} = data
        Mix.shell.info("""
        name:  #{name} 
        email: #{email}
        """)
      error ->
        Mix.shell.info("Failed for reason: #{inspect error}")
    end
  end
end
