defmodule Mix.Tasks.NervesHub.Deployment do
  use Mix.Task

  @shortdoc "Manages NervesHub deployments"

  @moduledoc """
  Manage HervesHub deployments

  ## list

    mix nerves_hub.deployment list

  ### Command line options

    * `--product` - (Optional) The product name to list deployments for.
      This defaults to the Mix Project config `:app` name.

  ## update

  Update values on a deployment. 

  ### Examples

  Update active firmware version

    mix nerves_hub.deployment update dev firmware fd53d87c-99ca-5770-5540-edb5058ced5b

  Activate / Deactivate a deployment

    mix nerves_hub.deployment update dev is_active true

  General useage:

    mix nerves_hub.firmware update [deployment_name] [key] [value]

  """

  import Mix.NervesHub.Utils
  alias NervesHub.API
  alias Mix.NervesHub.Shell

  @switches [
    product: :string
  ]

  def run(args) do
    Application.ensure_all_started(:nerves_hub)

    {opts, args} = OptionParser.parse!(args, strict: @switches)
    product = opts[:product] || default_product()

    case args do
      ["list"] ->
        list(product)

      ["update", deployment, key, value] ->
        update(product, deployment, key, value)

      _ ->
        render_help()
    end
  end

  def list(product) do
    case API.Deployment.list(product) do
      {:ok, %{"data" => []}} ->
        Shell.info("No deployments have been created for product: #{product}")

      {:ok, %{"data" => deployments}} ->
        Shell.info("")
        Shell.info("Deployments:")

        Enum.each(deployments, fn params ->
          Shell.info("------------")

          render_deployment(params)
          |> String.trim_trailing()
          |> Shell.info()

          Shell.info("------------")
        end)

        Shell.info("")

      error ->
        Shell.info("Failed to list deployments \nreason: #{inspect(error)}")
    end
  end

  defp update(product, deployment, key, value) do
    case API.Deployment.update(product, deployment, Map.put(%{}, key, value)) do
      {:ok, %{"data" => deployment}} ->
        Shell.info("")
        Shell.info("Deployment Updated:")

        render_deployment(deployment)
        |> String.trim_trailing()
        |> Shell.info()

        Shell.info("")

      error ->
        Shell.info("Failed to update deployment \nreason: #{inspect(error)}")
    end
  end

  defp render_deployment(params) do
    """
      name:      #{params["name"]}
      is_active: #{params["is_active"]}
      firmware:  #{params["firmware_uuid"]}
      #{render_conditions(params["conditions"])}
    """
  end

  defp render_conditions(conditions) do
    """
    conditions:
    """ <>
      if Map.get(conditions, "version") != "" do
        """
            version: #{conditions["version"]}
        """
      else
        ""
      end <>
      """
          #{render_tags(conditions["tags"])}
      """
  end

  defp render_tags(tags) do
    """
    tags: [#{Enum.join(tags, ", ")}]
    """
  end

  def render_help() do
    Shell.raise("""
    Invalid arguments

    Usage:
      mix nerves_hub.deployment list
      mix nerves_hub.deployment update [deployment_name] [key] [value]
    """)
  end
end
