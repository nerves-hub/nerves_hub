defmodule NervesHub.Channel.ConfigTest do
  use ExUnit.Case, async: true
  alias NervesHub.Channel.Config
  alias NervesHub.Certificate

  doctest Config

  describe "opts" do
    test "empty" do
      opts = Config.derive_unspecified_options([])

      assert opts[:url] == "wss://0.0.0.0:4001/socket/websocket"
      assert opts[:serializer] == Jason
      assert opts[:ssl_verify] == :verify_peer

      assert opts[:socket_opts] == [
               key: {:ECPrivateKey, ""},
               cert: "",
               cacerts: Certificate.ca_certs(),
               server_name_indication: false
             ]

      assert opts[:device_port] == 4001
      assert opts[:server_name_indication] == false
      assert opts[:cacerts] == nil
      assert opts[:device_host] == "0.0.0.0"
    end

    test "custom" do
      opts = Config.derive_unspecified_options(cacerts: [:red])

      assert opts[:url] == "wss://0.0.0.0:4001/socket/websocket"
      assert opts[:serializer] == Jason
      assert opts[:ssl_verify] == :verify_peer

      assert opts[:socket_opts] == [
               key: {:ECPrivateKey, ""},
               cert: "",
               cacerts: [:red],
               server_name_indication: false
             ]

      assert opts[:device_port] == 4001
      assert opts[:server_name_indication] == false
      assert opts[:cacerts] == [:red]
      assert opts[:device_host] == "0.0.0.0"
    end

    test "sni" do
      opts = Config.derive_unspecified_options(server_name_indication: "device.nerves-hub.org")

      assert opts[:url] == "wss://0.0.0.0:4001/socket/websocket"
      assert opts[:serializer] == Jason
      assert opts[:ssl_verify] == :verify_peer

      assert opts[:socket_opts] == [
               key: {:ECPrivateKey, ""},
               cert: "",
               cacerts: Certificate.ca_certs(),
               server_name_indication: 'device.nerves-hub.org'
             ]

      assert opts[:device_port] == 4001
      assert opts[:server_name_indication] == "device.nerves-hub.org"
      assert opts[:cacerts] == nil
      assert opts[:device_host] == "0.0.0.0"
    end
  end
end
