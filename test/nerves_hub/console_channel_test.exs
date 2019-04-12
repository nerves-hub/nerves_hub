defmodule NervesHub.ConsoleChannelTest do
  use ExUnit.Case, async: false
  alias NervesHub.{ClientMock, ConsoleChannel}
  alias PhoenixClient.Message

  doctest ConsoleChannel

  setup context do
    context = Map.put(context, :state, %ConsoleChannel.State{})
    :ok = Application.ensure_started(:iex)
    Application.put_env(:nerves_hub, :remote_iex, true)
    Mox.verify_on_exit!(context)
    context
  end

  describe "handle_info - Channel Messages" do
    test "iex_terminate", %{state: state} do
      iex_pid = spawn(fn -> :timer.sleep(10000) end)
      message = %Message{event: "iex_terminate"}

      {:noreply, new_state} = ConsoleChannel.handle_info(message, %{state | iex_pid: iex_pid})

      assert new_state.iex_pid == nil
      refute Process.alive?(iex_pid)
    end

    test "init - creates and links IEx server", %{state: state} do
      {:noreply, new_state} = ConsoleChannel.handle_info(%Message{event: "init"}, state)
      assert Process.alive?(new_state.iex_pid)
      group_leader = Process.info(new_state.iex_pid) |> Keyword.get(:group_leader)
      assert group_leader == self()
    end

    test "init - reuses existing IEx server in good state", %{state: state} do
      {:noreply, new_state} = ConsoleChannel.handle_info(%Message{event: "init"}, state)

      # Repeating same message with the new_state should just return it
      assert {:noreply, ^new_state} =
               ConsoleChannel.handle_info(%Message{event: "init"}, new_state)
    end

    test "init - resets IEx server when existing has mismatch group_leader", %{state: state} do
      Mox.expect(ClientMock, :handle_error, fn _ -> :ok end)
      iex_pid = spawn(fn -> :timer.sleep(10000) end)
      message = %Message{event: "init"}

      {:noreply, new_state} = ConsoleChannel.handle_info(message, %{state | iex_pid: iex_pid})
      assert new_state.iex_pid != iex_pid
    end

    test "io_reply - get_line", %{state: state} do
      state = %{state | request: {self(), "reply_as", "ignored"}}
      data = "wat"
      msg = %Message{event: "io_reply", payload: %{"data" => data, "kind" => "get_line"}}

      assert {:noreply, state} == ConsoleChannel.handle_info(msg, state)
      assert_receive {:io_reply, "reply_as", ^data}
    end

    test "phx_error - attempts rejoin", %{state: state} do
      Mox.expect(ClientMock, :handle_error, fn _ -> :ok end)
      msg = %Message{event: "phx_error", payload: %{}}
      assert ConsoleChannel.handle_info(msg, state) == {:noreply, state}
      assert_receive :join
    end

    test "phx_close - attempts rejoin", %{state: state} do
      Mox.expect(ClientMock, :handle_error, fn _ -> :ok end)
      msg = %Message{event: "phx_close", payload: %{}}
      assert ConsoleChannel.handle_info(msg, state) == {:noreply, state}
      assert_receive :join
    end
  end

  describe "handle_info - :io_request" do
    test "ignores :setopts" do
      req = {:io_request, self(), "reply_as", {:setopts, {}}}
      assert ConsoleChannel.handle_info(req, %{}) == {:noreply, %{}}
      assert_receive {:io_reply, "reply_as", {:error, :enotsup}}
    end

    test ":getopts" do
      req = {:io_request, self(), "reply_as", :getopts}
      assert ConsoleChannel.handle_info(req, %{}) == {:noreply, %{}}
      assert_receive {:io_reply, "reply_as", {:ok, [binary: true, encoding: :unicode]}}
    end

    test "ignores :get_geometry, :columns" do
      req = {:io_request, self(), "reply_as", {:get_geometry, :columns}}
      assert ConsoleChannel.handle_info(req, %{}) == {:noreply, %{}}
      assert_receive {:io_reply, "reply_as", {:error, :enotsup}}
    end

    test "ignores :get_geometry, :rows" do
      req = {:io_request, self(), "reply_as", {:get_geometry, :rows}}
      assert ConsoleChannel.handle_info(req, %{}) == {:noreply, %{}}
      assert_receive {:io_reply, "reply_as", {:error, :enotsup}}
    end

    test ":get_line", %{state: state} do
      req = {:io_request, self(), "reply_as", {:get_line, :unicode, "iex()>"}}
      {:noreply, new_state} = ConsoleChannel.handle_info(req, state)
      assert new_state.request == Tuple.delete_at(req, 0)
    end

    test "reports unknown :io_request", %{state: state} do
      Mox.expect(ClientMock, :handle_error, fn _ -> :ok end)
      req = {:io_request, self(), "reply_as", :wat}
      assert ConsoleChannel.handle_info(req, state) == {:noreply, state}
    end
  end

  test "reports unknown handle_info message" do
    Mox.expect(ClientMock, :handle_error, 2, fn _ -> :ok end)
    assert ConsoleChannel.handle_info(:wat, %{}) == {:noreply, %{}}
    assert ConsoleChannel.handle_info(%Message{event: "wat"}, %{}) == {:noreply, %{}}
  end
end
