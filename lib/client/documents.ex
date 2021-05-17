defmodule CosmosDbEx.Client.Documents do
  @moduledoc """
  This Container module provides functions for working with Cosmos DB containers.  These functions
  map to the same or similar operations found in the Cosmos Db rest api documentation.
  See: [Documents](https://docs.microsoft.com/en-us/rest/api/cosmos-db/documents)



  TODO(jeramyRR): Implement retries for when a request has been throttled.
    How will we know when a request has been throttled?  The response header, coming from Cosmos,
    will contain an entry called "x-ms-retry-after-ms".  This header indicates that the request was
    indeed throttled, and lets us know when we should try the request again.
    See [Common Azure Cosmos DB REST response headers](https://docs.microsoft.com/en-us/rest/api/cosmos-db/common-cosmosdb-rest-response-headers)
    for a list of common response headers.

  """

  use Timex
  alias CosmosDbEx.Response
  alias CosmosDbEx.Client.{Auth, Config}

  defprotocol Identifiable do
    @doc "Returns the id of the item."
    @spec get_id(t) :: String.t() | nil
    @fallback_to_any true
    def get_id(item)
  end

  defimpl Identifiable, for: Any do
    def get_id(item), do: item.id
  end

  defimpl Identifiable, for: Map do
    def get_id(item), do: item.id
  end

  @doc """
  Gets an item from the container.
  """
  def get_item(nil, _, _), do: raise("Cannot get a document without a valid Container.")
  def get_item(_, nil, _), do: raise("Cannot get a document without a valid id.")
  def get_item(_, _, nil), do: raise("Cannot get a document without a valid partition key.")

  def get_item(container, id, partition_key)
      when is_struct(container) and
             is_binary(id) and
             is_binary(partition_key) do
    "dbs/#{container.database}/colls/#{container.container_name}/docs/#{id}"
    |> send_get_request(partition_key)
    |> parse_response()
  end

  @doc """
  Creates a new document in the container.

  Note that the item being placed in CosmosDb must implement the Identifiable protocol.
  """
  def create_item(container, item, partition_key) do
    "dbs/#{container.database}/colls/#{container.container_name}/docs"
    |> send_post_request(item, partition_key)
    |> parse_response()
  end

  defp send_get_request(path, partition_keys) do
    key = Config.get_cosmos_db_key()
    key_type = "master"
    date = get_datetime_now()

    headers = build_common_headers("get", path, partition_keys, date, key, key_type)

    url = build_request_url(path)

    :get
    |> Finch.build(url, headers)
    |> Finch.request(CosmosDbEx.Application)
  end

  defp send_post_request(path, item, partition_keys) do
    key = Config.get_cosmos_db_key()
    key_type = "master"
    date = get_datetime_now()

    headers =
      build_common_headers(
        "post",
        path,
        partition_keys,
        date,
        key,
        key_type
      )

    url = build_request_url(path)

    :post
    |> Finch.build(url, headers, Jason.encode!(item))
    |> Finch.request(CosmosDbEx.Application)
  end

  defp build_request_url(path) do
    host_url = Config.get_cosmos_host_url()

    "https://#{host_url}/#{path}"
  end

  defp build_common_headers(
         http_verb,
         path,
         partition_keys,
         date,
         key,
         key_type
       ) do
    auth_signature = Auth.generate_auth_signature(http_verb, path, date, key, key_type)

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

  defp parse_response(
         {:ok,
          %Finch.Response{
            body: body,
            headers: headers,
            status: 200
          }}
       ),
       do: {:ok, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            body: body,
            headers: headers,
            status: 201
          }}
       ),
       do: {:ok, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 400,
            headers: headers,
            body: body
          }}
       ),
       do: {:bad_request, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 401,
            headers: headers,
            body: body
          }}
       ),
       do: {:unauthorized, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 403,
            headers: headers,
            body: body
          }}
       ),
       do: {:storage_limit_reached, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 404,
            headers: headers,
            body: body
          }}
       ),
       do: {:not_found, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 409,
            headers: headers,
            body: body
          }}
       ),
       do: {:conflict, build_client_response(headers, body)}

  defp parse_response(
         {:ok,
          %Finch.Response{
            status: 413,
            headers: headers,
            body: body
          }}
       ),
       do: {:entity_too_large, build_client_response(headers, body)}

  defp parse_response(%{error: error}), do: {:error, error}

  defp build_client_response(headers, body) do
    request_charge = get_request_charge(headers)
    request_duration = get_request_duration(headers)
    Response.new(request_charge, request_duration, Jason.decode!(body))
  end

  defp get_request_charge([{"x-ms-request-charge", request_charge} | _]), do: request_charge
  defp get_request_charge([_head | tail]), do: get_request_charge(tail)
  defp get_request_charge(_), do: nil

  defp get_request_duration([{"x-ms-request-duration-ms", request_duration} | _]),
    do: request_duration

  defp get_request_duration([_head | tail]), do: get_request_duration(tail)
  defp get_request_duration(_), do: nil
end
