defmodule NervesHub.API.User do
  alias NervesHub.API

  def me() do
    API.request(:get, "users/me")
  end
end
