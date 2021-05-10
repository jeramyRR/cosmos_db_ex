defmodule CosmosDbEx.Client do
  use Timex
  alias CosmosDbEx.Client.Auth

  # TODO(wisingle): Figure out a better way to get this configuration value that doesn't require
  # TODO(wisingle): the lib user to set env vars.
  @host_url System.get_env("COSMOS_DB_HOST_URL")

  def get_document(database, collection, id, partition_keys) do
    "dbs/#{database}/colls/#{collection}/docs/#{id}"
    |> send_get_request("docs", id, partition_keys)
    |> parse_response()
  end



  defp send_get_request(path, resource_type, resource_id, partition_keys) do
    key = get_cosmos_db_key()
    key_type = "master"

    date = get_datetime_now()

    headers = get_headers("get", resource_type, resource_id, partition_keys, date, key, key_type)

    url = build_request_url(path)

    IO.puts "Sending to #{url}"

    Finch.build(:get, url, headers)
    |> Finch.request(CosmosDbEx.Application)
  end

  defp build_request_url(path), do: "https://#{@host_url}/#{path}"

  defp get_headers(http_verb, resource_type, resource_id, partition_keys, date, key, key_type) do
    auth_signature =
      Auth.generate_auth_signature(http_verb, resource_type, resource_id, date, key, key_type)

    partition_keys_json = Jason.encode!([partition_keys])

    [
      {"Authorization", auth_signature},
      {"Accept", "application/json"},
      {"x-ms-date", date},
      {"x-ms-version", "2018-12-31"},
      {"x-ms-documentdb-partitionkey", partition_keys_json}
    ]
  end

  # Cosmos DB Rest API requires a the date to be in a specific format.
  defp get_datetime_now() do
    DateTime.utc_now()
    |> Timezone.convert("GMT")
    |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)
    |> String.downcase()
  end

  defp get_cosmos_db_key do
    key = Application.get_env(:cosmos_db_ex, :cosmos_db_key)

    if key do
      key
    else
      IO.puts "Getting key from environment"
      System.get_env("COSMOS_DB_KEY")
    end
  end

  defp parse_response(
    {:ok,
     %Finch.Response {
       body: body,
       headers: [
         {"cache-control", cache}
       ],
       status: 200
      }
    }
  ) do
    {
      :ok,
      %{
        #request_charge: request_charge,
        #request_duration: request_duration,
        body: Jason.decode!(body)
      }
    }
  end

  defp get_request_charge(headers) do

  end

  defp parse_response(
    {:ok,
     %Finch.Response {
       body: body,
       headers: headers,
       status: 200
      }
    }
  ) do
    {
      :ok,
      %{
        headers: headers,
        body: Jason.decode!(body)
      }
    }
  end

  defp parse_response(
    {:ok,
     %Finch.Response {
       status: 404,
       headers: [
       "x-ms-request-chart": request_charge,
       "x-ms-request-duration-ms": request_duration,
       ],
       body: body
      }
    }
  ) do
    {
      :not_found,
      %{
        request_charge: request_charge,
        request_duration: request_duration,
        body: Jason.decode!(body)
      }
    }
  end

  defp parse_response(
    {:ok,
     %Finch.Response {
       status: 401,
       body: body
      }
    }
  ) do
    {
      :unauthorized,
      body: Jason.decode!(body)
    }
  end
end
