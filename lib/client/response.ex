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
  """
  @enforce_keys [:body]
  defstruct request_charge: 0, request_duration: 0, body: nil

  def new(nil, nil, body) when is_map(body), do: new(0, 0, body)

  def new(request_charge, request_duration, body) when is_map(body) do
    %__MODULE__{
      request_charge: request_charge,
      request_duration: request_duration,
      body: body
    }
  end
end
