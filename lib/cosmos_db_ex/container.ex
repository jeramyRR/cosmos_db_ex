defmodule CosmosDbEx.Container do
  @moduledoc """
  A simple struct used to instruct the library which database and container to communicate with.
  """
  alias CosmosDbEx.Config

  @derive {Inspect, only: [:database, :container_name]}
  @enforce_keys [:database, :container_name, :database_key, :database_url]
  defstruct database: nil, container_name: nil, database_key: nil, database_url: nil

  @type t :: %__MODULE__{database: String.t(), container_name: String.t()}

  @spec new(String.t(), String.t()) :: t()
  def new(nil, _), do: raise("Cannot create Container struct with a nil database name.")
  def new(_, nil), do: raise("Cannot create Container struct with a nil container name.")

  def new(database, container_name) when is_binary(database) and is_binary(container_name) do
    %__MODULE__{
      database: database,
      container_name: container_name,
      database_key: Config.get_cosmos_db_key(),
      database_url: Config.get_cosmos_host_url()
    }
  end
end
