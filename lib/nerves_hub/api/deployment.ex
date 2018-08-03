defmodule NervesHub.API.Deployment do
  alias NervesHub.API

  def list(product_name) do
    API.request(:get, "deployments", %{product_name: product_name})
  end

  def update(product_name, deployment_name, params) do
    params = %{
      product_name: product_name,
      deployment: params
    }

    API.request(:put, "deployments/#{deployment_name}", params)
  end
end
