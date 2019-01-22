defmodule NervesHub.ClientTest do
  use ExUnit.Case, async: true
  alias NervesHub.{Client, ClientMock}

  doctest Client

  setup context, do: Mox.verify_on_exit!(context)

  test "update_available/2" do
    Mox.expect(ClientMock, :update_available, fn :data -> :apply end)
    assert Client.dispatch_update_available(:data) == :apply

    Mox.expect(ClientMock, :update_available, fn :data -> :wrong end)
    assert Client.dispatch_update_available(:data) == :apply

    Mox.expect(ClientMock, :update_available, fn :data -> :ignore end)
    assert Client.dispatch_update_available(:data) == :ignore

    Mox.expect(ClientMock, :update_available, fn :data -> {:reschedule, 1337} end)
    assert Client.dispatch_update_available(:data) == {:reschedule, 1337}
  end

  test "handle_fwup_message/2" do
    Mox.expect(ClientMock, :handle_fwup_message, fn :data -> :ok end)
    assert Client.dispatch_fwup_message(:data) == :ok
  end

  test "handle_error/2" do
    Mox.expect(ClientMock, :handle_error, fn :data -> :ok end)
    assert Client.dispatch_error(:data) == :ok
  end

  describe "apply_wrap doesn't propagate failures" do
    test "error" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> raise :something end)
      assert Client.dispatch_fwup_message(:data) == :ok
    end

    test "exit" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> exit(:reason) end)
      assert Client.dispatch_fwup_message(:data) == :ok
    end

    test "throw" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> throw(:reason) end)
      assert Client.dispatch_fwup_message(:data) == :ok
    end

    test "exception" do
      Mox.expect(ClientMock, :handle_fwup_message, fn :data -> Not.real() end)
      assert Client.dispatch_fwup_message(:data) == :ok
    end
  end
end
