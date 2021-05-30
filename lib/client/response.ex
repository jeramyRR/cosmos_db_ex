defmodule CosmosDbEx.Response do
  @moduledoc """
  Formatted response from CosmosDb.

  # Request Charge

  This is the R/U (Request Unit) charge that the query cost to return the response from Cosmos Db.
  In other words, this was the cost of all the database operations that had to happen in order
  for CosmosDb to read or write to/from the database. For more information on Request Units please
  see [Request Units in Azure Cosmos DB](https://docs.microsoft.com/en-us/azure/cosmos-db/request-units).

  # Request Duration

  This is the time, in milliseconds, that it took CosmosDb to execute the query sent.

  # Body

  This is the body of the response sent from Cosmos Db.  It is expected that the body will be a map.
  Additional items gathered from the response headers will be placed in the properties field of the
  Response struct.  Some convience methods will be provided for commonly used properties like
  'request charge', 'request duration', and 'continuation_token'.
  """
  @enforce_keys [:body]
  defstruct resource_id: nil,
            count: 0,
            body: nil,
            properties: %{}

  @type t :: %__MODULE__{
          resource_id: String.t(),
          count: integer(),
          body: map(),
          properties: map()
        }

  @doc """
  Returns the request charge (Cosmos Db's Request Unit measurement) of the request. Returns nil if
  no request charge is found in the response.
  """
  def get_request_charge(%__MODULE__{properties: %{request_charge: request_charge}}) do
    {ru, _} = Float.parse(request_charge)
    ru
  end

  def get_request_charge(_), do: nil

  @doc """
  Returns the request duration, in milliseconds, of the request. Returns nil if no request_duration
  is found.
  """
  def get_request_duration(%__MODULE__{properties: %{request_duration: request_duration}}) do
    request_duration
  end

  def get_request_duration(_), do: nil

  @doc """
  Returns the continuation token of the request.  This token can be sent with the next request to
  retrieve the next page of results from the query.

  # Example
    iex> container = Container.new("TestItemsDb", "ItemsContainer")
    iex> {:ok, response} = CosmosDbEx.Client.get_documents(container)
    iex> {:ok, response} = CosmosDbEx.Client.get_documents(container, CosmosDbEx.Response.get_continuation_token(response))

  Note that Cosmos Db returns results in pages of up to a maximum of 1000 items.

  Returns nil if no continuation token is found.  Nil also signals that there are no more items left
  from the query.
  """
  def get_continuation_token(%__MODULE__{
        properties: %{continuation_token: continuation_token}
      }) do
    continuation_token
  end

  def get_continuation_token(_), do: nil
end
