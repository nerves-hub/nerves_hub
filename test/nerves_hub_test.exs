defmodule NervesHubTest do
  use ExUnit.Case
  doctest NervesHub

  test "encode / decode keys" do
    keys = ["abcd", "efgh", "ijkl"]

    tmp_dir = Path.expand("test/tmp")
    File.mkdir_p(tmp_dir)

    key_file = Path.join(tmp_dir, "keys")
    File.write!(key_file, Enum.join(keys, "\n"), [:write])

    assert keys == NervesHub.public_keys(key_file)
  end
end
