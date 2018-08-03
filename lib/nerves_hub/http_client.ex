defmodule NervesHub.HTTPClient do
  use GenServer

  require Logger
  alias NervesHub.Fwup

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
    {:ok, fwup} = Fwup.start_link(self())
    Logger.configure(level: :error)

    {:ok,
     %{
       url: nil,
       content_length: 0,
       buffer: "",
       buffer_size: 0,
       filename: "",
       caller: nil,
       number_of_redirects: 0,
       fwup: fwup,
       callback: cb
     }}
  end

  def handle_call({:get, _url}, _from, %{number_of_redirects: n} = s) when n > 5 do
    GenServer.reply(s.caller, {:error, :too_many_redirects})
    {:noreply, %{s | url: nil, number_of_redirects: 0, caller: nil}}
  end

  def handle_call({:get, url}, from, s) do
    headers = [
      {'Content-Type', 'application/octet-stream'}
    ]

    http_opts = [timeout: :infinity, autoredirect: false]
    opts = [stream: :self, receiver: self(), sync: false]
    :httpc.request(:get, {String.to_charlist(url), headers}, http_opts, opts, :nerves_system_test)
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
    # size = byte_size(data) + s.buffer_size
    # buffer = s.buffer <> data
    Logger.debug("Send Chunk")
    Fwup.send_chunk(s.fwup, data)
    # put_progress(size, s.content_length)
    {:noreply, s}
  end

  def handle_info({:http, {_, :stream_end, _headers}}, s) do
    Logger.debug("Stream End")
    IO.write(:stderr, "\n")
    GenServer.reply(s.caller, {:ok, s.buffer})
    {:noreply, %{s | filename: "", content_length: 0, buffer: "", buffer_size: 0, url: nil}}
  end

  def handle_info({:http, {_ref, {{_, status_code, _}, headers, _body}}}, s)
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
        GenServer.reply(s.caller, {:error, status_code})
    end
  end

  def handle_info({:http, {error, _headers}}, s) do
    Logger.error("Error: #{inspect(error)}")
    GenServer.reply(s.caller, {:error, error})
    {:noreply, s}
  end

  def handle_info({:fwup, :done} = msg, s) do
    send(s.callback, msg)
    {:noreply, s}
  end

  defp start_httpc() do
    :inets.start(:httpc, profile: :nerves_system_test)

    opts = [
      max_sessions: 8,
      max_keep_alive_length: 4,
      max_pipeline_length: 4,
      keep_alive_timeout: 120_000,
      pipeline_timeout: 60_000
    ]

    :httpc.set_options(opts, :nerves_system_test)
  end
end
