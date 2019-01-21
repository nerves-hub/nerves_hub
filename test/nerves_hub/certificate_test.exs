defmodule NervesHub.CertificateTest do
  use ExUnit.Case, async: true
  alias NervesHub.Certificate

  doctest Certificate

  describe "pem_to_der/1" do
    test "decodes certificate" do
      pem = File.read!(Path.join([:code.priv_dir(:nerves_hub), "ca_certs", "ca.pem"]))
      assert is_binary(Certificate.pem_to_der(pem))
    end

    test "some values return empty string" do
      assert Certificate.pem_to_der("") == ""
      assert Certificate.pem_to_der(nil) == ""
    end
  end

  test "ca_certs/0" do
    certs = Certificate.ca_certs()
    assert length(certs) == 4
    for cert <- certs, do: assert(is_binary(cert))
  end

  test "public_keys/0" do
    assert is_list(Certificate.public_keys())
  end
end
