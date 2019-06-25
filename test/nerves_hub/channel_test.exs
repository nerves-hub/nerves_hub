defmodule NervesHub.ChannelTest do
  use ExUnit.Case, async: true
  alias NervesHub.{ClientMock, Channel}
  alias PhoenixClient.Message

  doctest Channel

  setup context, do: Mox.verify_on_exit!(context)

  describe "handle_in/3 - update" do
    test "no firmware url" do
      Mox.expect(ClientMock, :update_available, 0, fn _ -> :ok end)
      assert Channel.handle_info(%Message{event: "update"}, %{}) == {:noreply, %{}}
    end

    test "firmware url - apply" do
      Mox.expect(ClientMock, :update_available, fn _ -> :apply end)

      assert Channel.handle_info(
               %Message{event: "update", payload: %{"firmware_url" => ""}},
               %{}
             ) == {:noreply, %{}}
    end

    test "firmware url - ignore" do
      Mox.expect(ClientMock, :update_available, fn _ -> :ignore end)

      assert Channel.handle_info(
               %Message{event: "update", payload: %{"firmware_url" => ""}},
               %{}
             ) == {:noreply, %{}}
    end

    test "firmware url - reschedule" do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 999} end)

      assert {:noreply, state} =
               Channel.handle_info(%Message{event: "update", payload: data}, %{})

      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 1} end)

      assert {:noreply, %{} = state} =
               Channel.handle_info(%Message{event: "update", payload: data}, state)

      assert_receive {:update_reschedule, ^data}
    end

    test "firmware url - removes existing timer" do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn _ -> :ignore end)

      assert {:noreply, state} =
               Channel.handle_info(%Message{event: "update", payload: data}, %{
                 update_reschedule_timer: nil
               })

      refute Map.has_key?(state, :update_reschedule_timer)
    end

    test "catch all" do
      assert Channel.handle_info(:any, :state) == {:noreply, :state}
    end
  end

  test "handle_close" do
    assert Channel.handle_info(%Message{event: "phx_close", payload: %{}}, :state) ==
             {:noreply, :state}

    assert_receive :join
  end

  describe "handle_info" do
    test "fwup" do
      message = {:ok, 1, "message"}
      Mox.expect(ClientMock, :handle_fwup_message, fn ^message -> :ok end)
      assert Channel.handle_info({:fwup, message}, %{}) == {:noreply, %{}}
    end

    test "http_error" do
      error = "error"
      Mox.expect(ClientMock, :handle_error, fn ^error -> :apply end)
      assert Channel.handle_info({:http_error, error}, %{}) == {:noreply, %{}}
    end

    test "update_reschedule" do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn ^data -> :apply end)
      assert Channel.handle_info({:update_reschedule, data}, %{}) == {:noreply, %{}}
    end
  end

  describe "handle_info - down" do
    test "normal" do
      assert Channel.handle_info({:DOWN, :any, :process, :any, :normal}, :state) ==
               {:noreply, :state}
    end

    test "non-normal" do
      Mox.expect(ClientMock, :handle_error, 1, fn _ -> :ok end)

      assert Channel.handle_info({:DOWN, :any, :process, :any, :"non-normal"}, :state) ==
               {:stop, :"non-normal", :state}
    end
  end
end
