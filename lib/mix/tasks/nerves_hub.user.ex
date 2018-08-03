defmodule Mix.Tasks.NervesHub.User do
  use Mix.Task

  alias NervesHub.API
  alias Mix.NervesHub.Shell

  @shortdoc "Manages your NervesHub user account"

  @moduledoc """
  Manage your NervesHub user account.

  Users are authenticated to the NervesHub API by supplying a valid
  client certificate with every request. User certificates can be generated
  and managed on https://www.nerves-hub.org/account/certificates

  NervesHub will look for the following files in the location of $NERVES_HUB_HOME
    
    ca.pem:       A file that containes all known NervesHub Certificate Authority 
                  certificates needed to authenticate.
    user.pem:     A signed user account certificate.
    user-key.pem: The user account certificate private key.


  ## whoami

    mix nerves_hub.user whoami
  """

  @switches []

  def run(args) do
    Application.ensure_all_started(:nerves_hub)

    {opts, args} = OptionParser.parse!(args, strict: @switches)

    case args do
      ["whoami"] ->
        whoami()

      _ ->
        render_help()
    end
  end

  def whoami do
    case API.User.me() do
      {:ok, %{"data" => data}} ->
        %{"name" => name, "email" => email} = data

        Mix.shell().info("""
        name:  #{name} 
        email: #{email}
        """)

      error ->
        Mix.shell().info("Failed for reason: #{inspect(error)}")
    end
  end

  def render_help() do
    Shell.raise("""
    Invalid arguments

    Usage:
      mix nerves_hub.user whoami
      
    """)
  end
end
