defmodule CosmosDbEx.Container do
  @moduledoc """
  A simple struct used to instruct the library which database and container to communicate with.
  """

  @enforce_keys [:database, :container_name]
  defstruct database: nil, container_name: nil

  @type t :: %__MODULE__{database: String.t(), container_name: String.t()}

  @spec new(String.t(), String.t()) :: t()
  def new(nil, _), do: raise("Cannot create Container struct with a nil database name.")
  def new(_, nil), do: raise("Cannot create Container struct with a nil container name.")

  def new(database, container_name) do
    %__MODULE__{database: database, container_name: container_name}
  end
end
