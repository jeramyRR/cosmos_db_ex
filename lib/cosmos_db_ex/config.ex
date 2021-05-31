defmodule CosmosDbEx.Config do
  @moduledoc false

  require Logger

  def get_cosmos_db_key do
    case Application.get_env(:cosmos_db_ex, :cosmos_db_key) do
      key when not is_nil(key) ->
        key

      _ ->
        Logger.debug("Attempting to retrieve Cosmos DB key from the environment.")

        case System.get_env("COSMOS_DB_KEY") do
          key when not is_nil(key) ->
            key

          _ ->
            raise "A COSMOS DB KEY is required."
        end
    end
  end

  def get_cosmos_host_url do
    case Application.get_env(:cosmos_db_ex, :cosmos_db_host_url) do
      host_url when not is_nil(host_url) ->
        host_url

      _ ->
        Logger.debug("Attempting to retrieve Cosmos DB Host Url from the environment.")

        case System.get_env("COSMOS_DB_HOST_URL") do
          host_url when not is_nil(host_url) ->
            host_url

          _ ->
            raise "A host url for COSMOS DB is required."
        end
    end
  end
end
