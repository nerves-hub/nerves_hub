defmodule Mix.NervesHub.Utils do
  def default_product do
    config()[:app]
  end

  def default_firmware do
    images_path =
      (config()[:images_path] || Path.join([Mix.Project.build_path(), "nerves", "images"]))
      |> Path.expand()

    filename = "#{default_product()}.fw"
    Path.join(images_path, filename)
  end

  def metadata(firmware) do
    case System.cmd("fwup", ["-m", "-i", firmware]) do
      {metadata, 0} ->
        metadata =
          metadata
          |> String.trim()
          |> String.split("\n")
          |> Enum.map(&String.split(&1, "=", parts: 2))
          |> Enum.map(fn [k, v] -> {String.trim(k, "meta-"), String.trim(v, "\"")} end)
          |> Enum.into(%{})

        {:ok, metadata}

      {reason, _} ->
        {:error, reason}
    end
  end

  @spec fetch_metadata_item(String.t(), String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def fetch_metadata_item(metadata, key) when is_binary(key) do
    {:ok, regex} = "#{key}=\"(?<item>[^\n]+)\"" |> Regex.compile()

    case Regex.named_captures(regex, metadata) do
      %{"item" => item} -> {:ok, item}
      _ -> {:error, :not_found}
    end
  end

  @spec get_metadata_item(String.t(), String.t(), any()) :: String.t() | nil
  def get_metadata_item(metadata, key, default \\ nil) when is_binary(key) do
    case fetch_metadata_item(metadata, key) do
      {:ok, metadata_item} -> metadata_item
      {:error, :not_found} -> default
    end
  end

  defp config() do
    Mix.Project.config()
  end
end
