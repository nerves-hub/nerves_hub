defmodule NervesHub.Client.DefaultTest do
  use ExUnit.Case, async: true
  alias NervesHub.Client.Default

  doctest Default

  test "update_available/1" do
    assert Default.update_available(-1) == :apply
  end

  describe "handle_fwup_message/1" do
    test "progress" do
      assert Default.handle_fwup_message({:progress, 25}) == :ok
    end

    test "error" do
      assert Default.handle_fwup_message({:error, :any, "message"}) == :ok
    end

    test "warning" do
      assert Default.handle_fwup_message({:warning, :any, "message"}) == :ok
    end

    test "any" do
      assert Default.handle_fwup_message(:any) == :ok
    end
  end

  test "handle_error/1" do
    assert Default.handle_error(:error) == :ok
  end
end
