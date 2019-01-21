defmodule NervesHub.HTTPClient.Default do
  @moduledoc false

  alias NervesHub.HTTPClient

  @behaviour HTTPClient

  @impl HTTPClient
  def request(method, url, headers, body, opts \\ []) do
    method
    |> :hackney.request(url, headers, body, opts)
    |> resp()
  end

  defp resp({:ok, status_code, _headers, client_ref})
       when status_code >= 200 and status_code < 300 do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:ok, ""}

      {:ok, body} ->
        Jason.decode(body)

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp({:ok, _status_code, _headers, client_ref}) do
    case :hackney.body(client_ref) do
      {:ok, ""} ->
        {:error, ""}

      {:ok, body} ->
        resp =
          case Jason.decode(body) do
            {:ok, body} -> body
            body -> body
          end

        {:error, resp}

      error ->
        error
    end
  after
    :hackney.close(client_ref)
  end

  defp resp(resp) do
    {:error, resp}
  end
end
