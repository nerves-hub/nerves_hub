defmodule NervesHub.ChannelTest do
  use ExUnit.Case, async: true
  alias NervesHub.{ClientMock, Channel}
  alias PhoenixClient.Message

  doctest Channel

  setup do
    %{state: %Channel.State{}}
  end

  setup context, do: Mox.verify_on_exit!(context)

  describe "handle_in/3 - update" do
    test "no firmware url" do
      Mox.expect(ClientMock, :update_available, 0, fn _ -> :ok end)
      assert Channel.handle_info(%Message{event: "update"}, %{}) == {:noreply, %{}}
    end

    test "firmware url - apply", %{state: state} do
      Mox.expect(ClientMock, :update_available, fn _ -> :apply end)

      assert Channel.handle_info(
               %Message{event: "update", payload: %{"firmware_url" => ""}},
               state
             ) == {:noreply, %Channel.State{status: {:updating, 0}}}
    end

    test "firmware url - ignore" do
      Mox.expect(ClientMock, :update_available, fn _ -> :ignore end)

      assert Channel.handle_info(
               %Message{event: "update", payload: %{"firmware_url" => ""}},
               %{}
             ) == {:noreply, %{}}
    end

    test "firmware url - reschedule", %{state: state} do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 999} end)

      assert {:noreply, state} =
               Channel.handle_info(%Message{event: "update", payload: data}, state)

      Mox.expect(ClientMock, :update_available, fn _ -> {:reschedule, 1} end)

      assert {:noreply, %{} = state} =
               Channel.handle_info(%Message{event: "update", payload: data}, state)

      assert_receive {:update_reschedule, ^data}
    end

    test "catch all" do
      assert Channel.handle_info(:any, :state) == {:noreply, :state}
    end
  end

  test "handle_close", %{state: state} do
    # This fails without starting the connection Agent.
    # Not sure why
    # TODO: Manage this agent better. Remove from test
    NervesHub.Connection.start_link([])

    assert Channel.handle_info(%Message{event: "phx_close", payload: %{}}, state) ==
             {:noreply, %Channel.State{connected?: false}}

    assert_receive :join
  end

  describe "handle_info" do
    test "fwup", %{state: state} do
      message = {:ok, 1, "message"}
      Mox.expect(ClientMock, :handle_fwup_message, fn ^message -> :ok end)
      assert Channel.handle_info({:fwup, message}, state) == {:noreply, state}
    end

    test "http_error", %{state: state} do
      error = "error"
      Mox.expect(ClientMock, :handle_error, fn ^error -> :apply end)

      assert Channel.handle_info({:http_error, error}, state) ==
               {:noreply, %Channel.State{status: :update_failed}}
    end

    test "update_reschedule", %{state: state} do
      data = %{"firmware_url" => ""}
      Mox.expect(ClientMock, :update_available, fn ^data -> :apply end)

      assert Channel.handle_info({:update_reschedule, data}, state) ==
               {:noreply, %Channel.State{status: {:updating, 0}}}
    end
  end

  describe "handle_info - down" do
    test "normal", %{state: state} do
      assert Channel.handle_info({:DOWN, :any, :process, :any, :normal}, state) ==
               {:noreply, state}
    end

    test "non-normal", %{state: state} do
      Mox.expect(ClientMock, :handle_error, 1, fn _ -> :ok end)

      assert Channel.handle_info({:DOWN, :any, :process, :any, :"non-normal"}, state) ==
               {:noreply, %Channel.State{status: :update_failed}}
    end
  end
end
