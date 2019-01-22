defmodule NervesHub.Channel.ConfigTest do
  use ExUnit.Case, async: true
  alias NervesHub.Channel.Config
  alias NervesHub.Certificate

  doctest Config

  describe "opts" do
    test "empty" do
      assert Config.derive_unspecified_options([]) == [
               url: "wss://0.0.0.0:4001/socket/websocket",
               serializer: Jason,
               ssl_verify: :verify_peer,
               socket_opts: [
                 key: {:ECPrivateKey, ""},
                 cert: "",
                 cacerts: Certificate.ca_certs(),
                 server_name_indication: false
               ],
               device_port: 4001,
               server_name_indication: false,
               cacerts: nil,
               device_host: "0.0.0.0"
             ]
    end

    test "custom" do
      assert Config.derive_unspecified_options(cacerts: [:red]) == [
               url: "wss://0.0.0.0:4001/socket/websocket",
               serializer: Jason,
               ssl_verify: :verify_peer,
               socket_opts: [
                 key: {:ECPrivateKey, ""},
                 cert: "",
                 cacerts: [:red],
                 server_name_indication: false
               ],
               device_port: 4001,
               server_name_indication: false,
               device_host: "0.0.0.0",
               cacerts: [:red]
             ]
    end

    test "sni" do
      assert Config.derive_unspecified_options(server_name_indication: "device.nerves-hub.org") ==
               [
                 url: "wss://0.0.0.0:4001/socket/websocket",
                 serializer: Jason,
                 ssl_verify: :verify_peer,
                 socket_opts: [
                   key: {:ECPrivateKey, ""},
                   cert: "",
                   cacerts: Certificate.ca_certs(),
                   server_name_indication: 'device.nerves-hub.org'
                 ],
                 device_port: 4001,
                 cacerts: nil,
                 device_host: "0.0.0.0",
                 server_name_indication: "device.nerves-hub.org"
               ]
    end
  end
end
