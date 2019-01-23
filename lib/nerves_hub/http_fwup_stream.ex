defmodule NervesHub.HTTPFwupStream do
  @moduledoc """
  Download and install a firmware update.
  """

  use GenServer

  require Logger

  @runtime Application.get_env(:nerves_hub, :runtime)

  @redirect_status_codes [301, 302, 303, 307, 308]
  @httpc_profile __MODULE__

  @doc """
    a `callback` module is expected to be passed to `start_link/1`

  messages will be received in the shape:

  * `{:fwup_message, message}` - see the docs for
    [Fwup](https://hexdocs.pm/fwup/) for more info.
  * `{:http_error, {status_code, body}}`
  * `{:http_error, :timeout}`
  * `{:http_error, :too_many_redirects}`

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initiate the firmware download from the specified URL

  Optionally send progress reports to the specified pid.
  """
  @spec get(String.t(), pid()) :: :ok
  def get(url, update_pid) do
    GenServer.call(__MODULE__, {:get, url, update_pid})
  end

  @doc """
  Cancel an inprogress firmware update
  """
  @spec cancel_update() :: :ok
  def cancel_update() do
    GenServer.call(__MODULE__, :cancel_update)
  end

  @impl true
  def init(_opts) do
    :inets.start(:httpc, profile: @httpc_profile)

    httpc_opts = [
      max_sessions: 2,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]

    :httpc.set_options(httpc_opts, @httpc_profile)


    {:ok,
     %{
       url: nil,
       callback: nil,
       number_of_redirects: 0,
       timeout: 15000,
       fwup: nil
     }}
  end

  @impl true
  def handle_call({:get, url, cb}, _from, %{url: nil} = state) do
    with {:ok, fwup} <- Fwup.stream(cb, fwup_args())
    make_request(url)
    # {:ok, fwup} = Fwup.stream(cb, fwup_args())
    fwup = nil

    {:reply, :ok, %{state | url: url, callback: cb}}
  end

  @impl true
  def handle_call({:get, _url, _pid}, _from, state) do
    {:reply, {:error, "install in progress"}, state}
  end

  def handle_call(:cancel_update, _from, state) do

  end

  @impl true
  def handle_info({:http, {_, :stream_start, headers}}, s) do
    Logger.debug("Stream Start: #{inspect(headers)}")

    {:noreply, s}
  end

  @impl true
  def handle_info({:http, {_, :stream, data}}, s) do
    Logger.debug("Got #{byte_size(data)} bytes")
    # Fwup.send_chunk(s.fwup, data)
    {:noreply, s, s.timeout}
  end

  @impl true
  def handle_info({:http, {_, :stream_end, _headers}}, s) do
    Logger.debug("Stream End")
    GenServer.reply(s.caller, :ok)
    {:noreply, %{s | url: nil}}
  end

  @impl true
  def handle_info({:http, {_ref, {{_, status_code, _}, headers, body}}}, s)
      when status_code in @redirect_status_codes do
    Logger.debug("Redirect")

    case get_header(headers, 'location') do
      nil ->
        {:stop, {:http_error, {status_code, body}}, s}

      next_url ->
        if s.number_of_redirects < 5 do
          make_request(next_url)
          {:noreply, %{s | number_of_redirects: s.number_of_redirects + 1}}
        else
          {:stop, {:error, {:http_error, :too_many_redirects}}, s}
        end
    end
  end

  @impl true
  def handle_info({:http, {_ref, {{_, status_code, _}, _headers, body}}}, s) do
    Logger.error("Error: #{status_code} #{inspect(body)}")
    {:stop, {:error, {:http_error, {status_code, body}}}, s}
  end

  @impl true
  def handle_info(:timeout, s) do
    Logger.error("Error: timeout")
    {:stop, {:error, {:http_error, :timeout}}, s}
  end

  @impl true
  def terminate(:normal, state) do
    GenServer.stop(state.fwup, :normal)
    :inets.stop(:httpc, @httpc_profile)
    :noop
  end

  @impl true
  def terminate({:error, reason}, state) do
    state.callback && send(state.callback, reason)
    GenServer.stop(state.fwup, :normal)
    :inets.stop(:httpc, @httpc_profile)
  end

  defp send_notification(nil, _what), do: :ok
  defp send_notification(pid, what) do
    send(pid, what)
  end

  defp fwup_args() do
    devpath = @runtime.install_device_path()
    fwup_public_keys = NervesHub.Certificate.public_keys()

    if fwup_public_keys == [] do
      Logger.error("No fwup public keys were configured for nerves_hub.")
      Logger.error("This means that firmware signatures are not being checked.")
      Logger.error("nerves_hub won't allow this in the future.")
    end

    key_args =
      Enum.reduce(fwup_public_keys, [], fn public_key, args -> ["--public-key", public_key | args] end)

    ["--apply", "--no-unmount", "-d", devpath, "--task", "upgrade"] ++ key_args
  end

  defp make_request(url) do
    headers = [
      {'Content-Type', 'application/octet-stream'}
    ]

    http_opts = [timeout: :infinity, autoredirect: false]
    opts = [stream: :self, receiver: self(), sync: false]

    :httpc.request(
      :get,
      {String.to_charlist(url), headers},
      http_opts,
      opts,
      @httpc_profile
    )
  end

  def get_header(headers, key) do
    Enum.find_value(headers, fn {k, v} -> k == key && v end)
  end
end
