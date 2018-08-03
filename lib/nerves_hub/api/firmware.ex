defmodule NervesHub.API.Firmware do
  alias NervesHub.API

  def list(product_name) do
    API.request(:get, "firmwares", %{product_name: product_name})
  end

  def create(tar) do
    API.file_request(:post, "firmwares", tar)
  end

  def delete(uuid) do
    API.request(:delete, "firmwares/#{uuid}")
  end
end
