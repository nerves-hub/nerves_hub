defmodule NervesHub.CertificateTest do
  use ExUnit.Case, async: true
  alias NervesHub.Certificate

  doctest Certificate

  test "ca_certs/0" do
    certs = Certificate.ca_certs()
    assert length(certs) == 4
    for cert <- certs, do: assert(is_binary(cert))
  end

  test "fwup_public_keys/0" do
    assert is_list(Certificate.fwup_public_keys())
  end
end
