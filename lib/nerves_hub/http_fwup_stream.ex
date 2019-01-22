defmodule NervesHub.HTTPFwupStream do
  @moduledoc """
  Handles streaming a fwupdate via HTTP.

  a `callback` module is expected to be passed to `start_link/1`

  messages will be received in the shape:

  * `{:fwup_message, message}` - see the docs for
    [Fwup](https://hexdocs.pm/fwup/) for more info.
  * `{:http_error, {status_code, body}}`
  * `{:http_error, :timeout}`
  * `{:http_error, :too_many_redirects}`
  """

  use GenServer

  require Logger

  @redirect_status_codes [301, 302, 303, 307, 308]

  def start_link(cb) do
    start_httpc()
    GenServer.start_link(__MODULE__, [cb])
  end

  def stop(pid) do
    GenServer.stop(pid)
  end

  def get(pid, url) do
    GenServer.call(pid, {:get, url}, :infinity)
  end

  def init([cb]) do
    devpath = Nerves.Runtime.KV.get("nerves_fw_devpath") || "/dev/mmcblk0"
    args = ["--apply", "--no-unmount", "-d", devpath, "--task", "upgrade"]

    fwup_public_keys = NervesHub.Certificate.public_keys()

    if fwup_public_keys == [] do
      Logger.error("No fwup public keys were configured for nerves_hub.")
      Logger.error("This means that firmware signatures are not being checked.")
      Logger.error("nerves_hub won't allow this in the future.")
    end

    args =
      Enum.reduce(fwup_public_keys, args, fn public_key, args ->
        args ++ ["--public-key", public_key]
      end)

    {:ok, fwup} = Fwup.stream(cb, args)

    {:ok,
     %{
       url: nil,
       callback: cb,
       content_length: 0,
       buffer: "",
       buffer_size: 0,
       filename: "",
       caller: nil,
       number_of_redirects: 0,
       timeout: 15000,
       fwup: fwup
     }}
  end

  def terminate(:normal, state) do
    GenServer.stop(state.fwup, :normal)
    :noop
  end

  def terminate({:error, reason}, state) do
    state.caller && GenServer.reply(state.caller, reason)
    state.callback && send(state.callback, reason)
    GenServer.stop(state.fwup, :normal)
  end

  def handle_call({:get, _url}, _from, %{number_of_redirects: n} = s) when n > 5 do
    {:stop, {:error, {:http_error, :too_many_redirects}}, s}
  end

  def handle_call({:get, url}, from, s) do
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
      :nerves_hub_fwup_stream
    )

    {:noreply, %{s | url: url, caller: from}}
  end

  def handle_info({:http, {_, :stream_start, headers}}, s) do
    Logger.debug("Stream Start: #{inspect(headers)}")

    content_length =
      case Enum.find(headers, fn {key, _} -> key == 'content-length' end) do
        nil ->
          0

        {_, content_length} ->
          {content_length, _} =
            content_length
            |> to_string()
            |> Integer.parse()

          content_length
      end

    filename =
      case Enum.find(headers, fn {key, _} -> key == 'content-disposition' end) do
        nil ->
          Path.basename(s.url)

        {_, filename} ->
          filename
          |> to_string
          |> String.split(";")
          |> List.last()
          |> String.trim()
          |> String.trim("filename=")
      end

    {:noreply, %{s | content_length: content_length, filename: filename}}
  end

  def handle_info({:http, {_, :stream, data}}, s) do
    Fwup.send_chunk(s.fwup, data)
    {:noreply, s, s.timeout}
  end

  def handle_info({:http, {_, :stream_end, _headers}}, s) do
    Logger.debug("Stream End")
    GenServer.reply(s.caller, {:ok, s.buffer})
    {:noreply, %{s | filename: "", content_length: 0, buffer: "", buffer_size: 0, url: nil}}
  end

  def handle_info({:http, {_ref, {{_, status_code, _}, headers, body}}}, s)
      when status_code in @redirect_status_codes do
    Logger.debug("Redirect")

    case Enum.find(headers, fn {key, _} -> key == 'location' end) do
      {'location', next_url} ->
        handle_call({:get, List.to_string(next_url)}, s.caller, %{
          s
          | buffer: "",
            buffer_size: 0,
            number_of_redirects: s.number_of_redirects + 1
        })

      _ ->
        {:stop, {:http_error, {status_code, body}}, s}
    end
  end

  def handle_info({:http, {_ref, {{_, status_code, _}, _headers, body}}}, s) do
    Logger.error("Error: #{status_code} #{inspect(body)}")
    {:stop, {:error, {:http_error, {status_code, body}}}, s}
  end

  def handle_info(:timeout, s) do
    Logger.error("Error: timeout")
    {:stop, {:error, {:http_error, :timeout}}, s}
  end

  defp start_httpc() do
    :inets.start(:httpc, profile: :nerves_hub_fwup_stream)

    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]

    :httpc.set_options(opts, :nerves_hub_fwup_stream)
  end
end
