defmodule NervesHub.HTTPClient.DefaultTest do
  use ExUnit.Case, async: true
  alias NervesHub.HTTPClient.Default

  doctest Default

  describe "request/4" do
    test "hackney.request/5 error" do
      assert Default.request(:get, "file://nope", [], []) == {:error, {:error, :nxdomain}}
    end
  end
end
