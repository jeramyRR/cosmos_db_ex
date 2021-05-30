defmodule CosmosDbEx.Documents do
  @moduledoc false

  ###
  # This Container module provides functions for working with Cosmos DB containers.  These functions
  # map to the same or similar operations found in the Cosmos Db rest api documentation.
  # See: [Documents](https://docs.microsoft.com/en-us/rest/api/cosmos-db/documents)
  #
  #
  #
  # TODO(jeramyRR): Implement retries for when a request has been throttled.
  # How will we know when a request has been throttled?  The response header, coming from Cosmos,
  # will contain an entry called "x-ms-retry-after-ms".  This header indicates that the request was
  # indeed throttled, and lets us know when we should try the request again.
  # See [Common Azure Cosmos DB REST response headers](https://docs.microsoft.com/en-us/rest/api/cosmos-db/common-cosmosdb-rest-response-headers)
  # for a list of common response headers.
  ###
  require Logger

  use Timex
  alias CosmosDbEx.{Auth, Config, Container, Response}

  @accept_header "Accept"
  @authorization_header "Authorization"
  @content_type_header "Content-Type"
  @continuation_token_header "x-ms-continuation"
  @date_header "x-ms-date"
  @is_query_header "x-ms-documentdb-isquery"
  @max_item_count_headeer "x-ms-max-item-count"
  @partition_key_header "x-ms-documentdb-partitionkey"
  @request_charge_header "x-ms-request-charge"
  @request_duration_header "x-ms-request-duration-ms"
  @user_agent_header "User-Agent"
  @version_header "x-ms-version"

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
    partition_keys_json = Jason.encode!([partition_key])
    headers = [{@partition_key_header, partition_keys_json}]

    "dbs/#{container.database}/colls/#{container.container_name}/docs/#{id}"
    |> send_get_request(headers)
    |> parse_response()
  end

  @spec get_items(Container.t(), integer()) :: {:ok, Response.t()}
  def get_items(container, max_item_count \\ 100, continuation_token \\ nil) do
    headers =
      case continuation_token == nil do
        true ->
          [{@max_item_count_headeer, "#{max_item_count}"}]

        false ->
          [
            {@max_item_count_headeer, "#{max_item_count}"},
            {@continuation_token_header, Jason.encode!(continuation_token)}
          ]
      end

    "dbs/#{container.database}/colls/#{container.container_name}/docs"
    |> send_get_request(headers)
    |> parse_response()
  end

  def query(container, query_text, params) do
    structured_params =
      params
      |> Enum.reduce([], fn {key, value}, acc -> [%{name: "@#{key}", value: value} | acc] end)

    body = %{
      query: query_text,
      parameters: structured_params
    }

    headers = [
      {@is_query_header, "true"},
      {@content_type_header, "application/query+json"}
    ]

    "dbs/#{container.database}/colls/#{container.container_name}/docs"
    |> send_post_request(body, headers)
    |> parse_response()
  end

  @doc """
  Creates a new document in the container.

  Note that the item being placed in CosmosDb must implement the Identifiable protocol.
  """
  def create_item(container, item, partition_key) do
    partition_keys_json = Jason.encode!([partition_key])
    headers = [{@partition_key_header, partition_keys_json}]

    "dbs/#{container.database}/colls/#{container.container_name}/docs"
    |> send_post_request(item, headers)
    |> parse_response()
  end

  defp send_get_request(path, headers) do
    headers =
      case length(headers) == 0 do
        true -> build_common_headers("get", path)
        false -> Enum.concat(build_common_headers("get", path), headers)
      end

    url = build_request_url(path)

    :get
    |> Finch.build(url, headers)
    |> Finch.request(CosmosDbEx.Application)
  end

  defp send_post_request(path, item, headers) do
    headers =
      case length(headers) == 0 do
        true -> build_common_headers("post", path)
        false -> Enum.concat(build_common_headers("post", path), headers)
      end

    url = build_request_url(path)

    body = Jason.encode!(item)

    :post
    |> Finch.build(url, headers, body)
    |> Finch.request(CosmosDbEx.Application)
  end

  defp build_request_url(path) do
    host_url = Config.get_cosmos_host_url()

    "https://#{host_url}/#{path}"
  end

  defp build_common_headers(http_verb, path) do
    key = Config.get_cosmos_db_key()
    key_type = "master"
    date = get_datetime_now()

    auth_signature = Auth.generate_auth_signature(http_verb, path, date, key, key_type)

    [
      {@authorization_header, auth_signature},
      {@accept_header, "application/json"},
      {@date_header, date},
      {@version_header, "2018-12-31"},
      {@user_agent_header, "CosmosDbEx.Client.Documents"}
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

  defp build_client_response(headers, body) do
    Logger.debug("Body: #{inspect(body)}")

    headers_map = flatten_headers(headers)

    Jason.decode!(body)
    |> build_response(headers_map)
  end

  defp build_response(
         %{"Documents" => documents, "_count" => count, "_rid" => rid},
         headers
       ) do
    %Response{
      body: %{"Documents" => documents},
      properties: %{
        request_charge: headers[@request_charge_header],
        request_duration: headers[@request_duration_header],
        continuation_token: decode_continuation_token(headers[@continuation_token_header])
      },
      count: count,
      resource_id: rid
    }
  end

  defp build_response(body, headers) do
    %Response{
      body: body,
      properties: %{
        request_charge: headers[@request_charge_header],
        request_duration: headers[@request_duration_header]
      },
      count: 1
    }
  end

  defp flatten_headers(headers) do
    headers
    |> Enum.reduce(%{}, fn {key, value}, acc -> Map.put_new(acc, key, value) end)
  end

  defp decode_continuation_token(nil), do: nil
  defp decode_continuation_token(token), do: Jason.decode!(token)
end
