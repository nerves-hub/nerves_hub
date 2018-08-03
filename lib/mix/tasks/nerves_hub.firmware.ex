defmodule Mix.Tasks.NervesHub.Firmware do
  use Mix.Task

  @shortdoc "Manages NervesHub firmware"

  @moduledoc """
  Manage HervesHub Firmwares

  ## publish

  Upload signed firmware to NervesHub. Supplying a path to the firmware file
  is optional. If it is not specified, NervesHub will locate the firmware
  based off the project settings.

    mix nerves_hub.firmware.publish [Optional: /path/to/app.firmware]

  ### Command line options

    * `--product` - (Optional) The product name to publish the firmware to.
      This defaults to the Mix Project config `:app` name.
    * `--deploy` - (Optional) The name of a deployment to update following
      firmware publish. This key can be passed multiple times to update
      multiple deployments.

  ## list

    mix nerves_hub.firmware list

  ### Command line options

    * `--product` - (Optional) The product name to publish the firmware to.
      This defaults to the Mix Project config `:app` name.

  ## delete

  Firmware can only be deleted if it is not associated to any deployment.
  Call `list` to retreive firmware uuids

    mix nerves_hub.firmware delete [firmware_uuid]

  """

  import Mix.NervesHub.Utils
  alias NervesHub.API
  alias Mix.NervesHub.Shell

  @switches [
    product: :string,
    deploy: :keep
  ]

  def run(args) do
    Application.ensure_all_started(:nerves_hub)

    {opts, args} = OptionParser.parse!(args, strict: @switches)
    product = opts[:product] || default_product()

    case args do
      ["list"] ->
        list(product)

      ["publish" | []] ->
        default_firmware()
        |> publish_confirm(opts)

      ["publish", firmware] when is_binary(firmware) ->
        firmware
        |> Path.expand()
        |> publish_confirm(opts)

      ["delete", uuid] when is_binary(uuid) ->
        delete_confirm(uuid)

      _ ->
        render_help()
    end
  end

  def list(product) do
    case API.Firmware.list(product) do
      {:ok, %{"data" => []} = resp} ->
        Shell.info("No firmware has been published for product: #{product}")

      {:ok, %{"data" => firmwares} = resp} ->
        Shell.info("")
        Shell.info("Firmwares:")

        Enum.each(firmwares, fn metadata ->
          Shell.info("------------")

          render_firmware(metadata)
          |> String.trim_trailing()
          |> Shell.info()
        end)

        Shell.info("")

      error ->
        Shell.info("Failed to list firmware \nreason: #{inspect(error)}")
    end
  end

  defp publish_confirm(firmware, opts) do
    with true <- File.exists?(firmware),
         {:ok, metadata} <- metadata(firmware) do
      Shell.info("------------")

      render_firmware(metadata)
      |> String.trim_trailing()
      |> Shell.info()

      if Mix.shell().yes?("Publish Firmware?") do
        publish(firmware, opts)
      end
    else
      false ->
        Shell.info("Cannot find firmware at #{firmware}")

      {:error, reason} ->
        Shell.info("Unable to parse firmware metadata: #{inspect(reason)}")
    end
  end

  defp delete_confirm(uuid) do
    Shell.info("UUID: #{uuid}")

    if Mix.shell().yes?("Delete Firmware?") do
      delete(uuid)
    end
  end

  defp publish(firmware, opts) do
    case API.Firmware.create(firmware) do
      {:ok, %{"data" => %{} = firmware}} ->
        Shell.info("Firmware published successfully")

        Keyword.get_values(opts, :deploy)
        |> maybe_deploy(firmware)

      error ->
        Shell.info("Failed to publish firmware \nreason: #{inspect(error)}")
    end
  end

  defp delete(uuid) do
    API.Firmware.delete(uuid) |> IO.inspect()
    # case  do
    #   {:ok, %{"data" => %{} = firmware}} ->
    #     Shell.info("Firmware published successfully")
    #   error ->
    #     Shell.info("Failed to publish firmware \nreason: #{inspect error}")
    # end
  end

  defp maybe_deploy([], _), do: :ok

  defp maybe_deploy(deployments, firmware) do
    Enum.each(deployments, fn deployment_name ->
      Shell.info("Deploying firmware to #{deployment_name}")

      Mix.Task.run("nerves_hub.deployment", [
        "update",
        deployment_name,
        "firmware",
        firmware["uuid"]
      ])
    end)
  end

  defp render_firmware(params) do
    """
      product:      #{params["product"]}
      version:      #{params["version"]}
      platform:     #{params["platform"]}
      architecture: #{params["architecture"]}
      uuid:         #{params["uuid"]}
    """
  end

  def render_help() do
    Shell.raise("""
    Invalid arguments

    Usage:
      mix nerves_hub.firmware list
      mix nerves_hub.firmware publish
      mix nerves_hub.firmware delete
      
    """)
  end
end
