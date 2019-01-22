defmodule NervesHub.Channel.FirmwareChannelTest do
  use ExUnit.Case, async: true
  alias NervesHub.ClientMock
  alias NervesHub.Channel.FirmwareChannel

  doctest FirmwareChannel

  setup context, do: Mox.verify_on_exit!(context)

  test "topic/0" do
    fw_uuid = NervesHub.Runtime.NervesKV.running_firmware_uuid()
    assert FirmwareChannel.topic() == "firmware:#{fw_uuid}"
  end

  describe "handle_in/3 - update" do
    test "no firmware url" do
      Mox.expect(ClientMock, :update_available, 0, fn _ -> :ok end)
      assert FirmwareChannel.handle_in("update", %{}, %{}) == {:noreply, %{}}
    end

    test "firmware url - apply" do
      Mox.expect(ClientMock, :update_available, fn _ -> :apply end)
      assert FirmwareChannel.handle_in("update", %{"firmware_url" => ""}, %{}) == {:noreply, %{}}
    end

    test "firmware url - ignore" do
      Mox.expect(ClientMock, :update_available, fn _ -> :ignore end)
      assert FirmwareChannel.handle_in("update", %{"firmware_url" => ""}, %{}) == {:noreply, %{}}
    end

    test "firmware url - reschedule" do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 999} end)
      assert {:noreply, state} = FirmwareChannel.handle_in("update", data, %{})
      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 1} end)
      assert {:noreply, %{} = state} = FirmwareChannel.handle_in("update", data, state)
      assert_receive {:update_reschedule, ^data}
    end
  end

  describe "handle_reply" do
    test "ok join" do
      Mox.expect(ClientMock, :update_available, 0, fn :data -> :ignore end)

      assert FirmwareChannel.handle_reply(
               {:ok, :join, %{"response" => %{}, "status" => "ok"}, :any},
               %{}
             ) == {:noreply, %{}}
    end

    test "ok join - calls update_available" do
      Mox.expect(ClientMock, :update_available, fn :data -> :ignore end)

      assert FirmwareChannel.handle_reply(
               {:ok, :join, %{"response" => %{"firmware_url" => ""}, "status" => "ok"}, :any},
               %{}
             ) == {:noreply, %{}}
    end

    test "error join" do
      Mox.expect(ClientMock, :handle_error, fn :reason -> :ok end)

      assert FirmwareChannel.handle_reply(
               {:error, :join, %{"response" => %{"reason" => :reason}, "status" => "error"}},
               :state
             ) == {:stop, :reason, :state}
    end

    test "catch all" do
      assert FirmwareChannel.handle_reply(:any, :state) == {:noreply, :state}
    end
  end

  test "handle_close" do
    assert FirmwareChannel.handle_close(:payload, :state) == {:noreply, :state}
    assert_receive :rejoin
  end

  describe "handle_info" do
    test "fwup" do
      message = {:ok, 1, "message"}
      Mox.expect(ClientMock, :handle_fwup_message, fn ^message -> :ok end)
      assert FirmwareChannel.handle_info({:fwup, message}, %{}) == {:noreply, %{}}
    end

    test "http_error" do
      error = "error"
      Mox.expect(ClientMock, :handle_error, fn ^error -> :apply end)
      assert FirmwareChannel.handle_info({:http_error, error}, %{}) == {:noreply, %{}}
    end

    test "update_reschedule" do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn ^data -> :apply end)
      assert FirmwareChannel.handle_info({:update_reschedule, data}, %{}) == {:noreply, %{}}
    end
  end

  describe "handle_info - down" do
    test "normal" do
      assert FirmwareChannel.handle_info({:DOWN, :any, :process, :any, :normal}, :state) ==
               {:noreply, :state}
    end

    test "non-normal" do
      Mox.expect(ClientMock, :handle_error, 1, fn _ -> :ok end)

      assert FirmwareChannel.handle_info({:DOWN, :any, :process, :any, :"non-normal"}, :state) ==
               {:stop, :"non-normal", :state}
    end
  end
end
