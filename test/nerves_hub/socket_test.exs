defmodule NervesHub.SocketTest do
  use ExUnit.Case, async: true
  alias NervesHub.{Certificate, Socket}

  doctest Socket

  describe "opts" do
    test "nil" do
      assert Socket.opts(nil) == [
               url: "wss://0.0.0.0:4001/socket/websocket",
               serializer: Jason,
               ssl_verify: :verify_peer,
               transport_opts: [
                 socket_opts: [
                   key: {:ECPrivateKey, ""},
                   cert: "",
                   cacerts: Certificate.ca_certs(),
                   server_name_indication: 'device.nerves-hub.org'
                 ]
               ]
             ]
    end

    test "custom" do
      assert Socket.opts(cacerts: [:red]) == [
               url: "wss://0.0.0.0:4001/socket/websocket",
               serializer: Jason,
               ssl_verify: :verify_peer,
               transport_opts: [
                 socket_opts: [
                   key: {:ECPrivateKey, ""},
                   cert: "",
                   cacerts: [:red],
                   server_name_indication: 'device.nerves-hub.org'
                 ]
               ],
               cacerts: [:red]
             ]
    end
  end

  test "cert/1" do
    assert Socket.cert([]) == {:cert, ""}
  end

  test "key/1" do
    assert Socket.key([]) == {:key, {:ECPrivateKey, ""}}
  end
end
