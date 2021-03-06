defmodule CosmosDbEx do
  @moduledoc """
  Contains the basic functions needed to communicate with CosmosDb.

  ## Configuration

  There are specific configuration values that must be present in order to communicate with your
  instance of Cosmos Db.  They are:

    * `COSMOS DB KEY` - This is either the *primary* or *secondary* Read-Write key of your database.
    You can find these keys under the 'Keys' tab of your databases settings.
    This value can be set in your apps config using `:cosmos_db_key` or as an environment variable
    named `COSMOS_DB_KEY`.

    * `COSMOS DB HOST URL` - This is the URI to your Cosmos DB instance. The value can be found
    under the Essentials section of your Cosmos Db Overview.
    This value can be set in your apps config using `:cosmos_db_host_url` or as an environment
    variable named `COSMOS_DB_HOST_URL`.


  Example using your apps configuration settings:

      config :cosmos_db_ex,
        cosmos_db_key: "{your_primary_or_secondary_key_here}",
        cosmos_db_host_url: "https://your-cosmos-db.documents.azure.com/",

  Remember that your keys are **secrets** that should never be saved in any version control system. If
  you're going to use the config option please take caution and look at using a config provider
  that retrieves the secrets from a vault or the environment.
  """
  alias CosmosDbEx.{Container, Documents}

  @doc """
  Retrieve a document by it's document id and partition key.

  ## Examples

      iex> container = CosmosDbEx.Container.new("database", "container")
      iex> item_id = "00000000-0000-0000-0000-000000000000"
      iex> partition_key = item_id
      iex> CosmosDbEx.get_document(container, item_id, partition_key)
      {:ok,
       %CosmosDbEx.Response{
        body: %{
          "_attachments" => "attachments/",
          "_etag" => ""00000000-0000-0000-0000-000000000000"",
          "_rid" => "AAAAAAAAAAAAAAAAA==",
          "_self" => "dbs/AAAAAA==/colls/AAAAAAAAAAA=/docs/AAAAAAAAAAAAAAAAAAAAAA==/",
          "_ts" => 1620141668,
          "id" => "00000000-0000-0000-0000-000000000000",
          "name" => "Test item"
        },
        properties: %{
          request_charge: "1",
          request_duration: "0.585"
        }
       }
      }

  """
  @spec get_document(Container.t(), String.t(), String.t()) ::
          {:ok
           | :bad_request
           | :conflict
           | :entity_too_large
           | :not_found
           | :storage_limit_reached
           | :unauthorized, CosmosDbEx.Response.t()}
  def get_document(container, id, partition_key) when is_struct(container) do
    container
    |> Documents.get_item(id, partition_key)
  end

  @doc """
  Retrieve all documents in the container.  This function defaults to retrieving 100 documents at a
  time (this is Cosmos Db's default).  You can increase the amount of items returned by calling
  `get_documents(container, max_item_count)` with any number up to 1000 (Cosmos Dbs max).

  If Cosmos Db has more documents than the query returned there will be a `Continuation Token` present
  in the properties (has the key `continuation_token`). You continue retrieving all the documents
  by using the Continuation Token in your next call to `get_documents`.  See the second example

  ## Examples

    Retrieve all documents from a container using the default max_items of 100 and no continuation
    token.

      iex> CosmosDbEx.Container.new("database", "container") |> CosmosDbEx.get_documents()
      {:ok,
       %CosmosDbEx.Response{
        body: %{
          "Documents" => [
            %{
              "_attachments" => "attachments/",
              "_etag" => "\"0200c45b-0000-0200-0000-609166640000\"",
              "_rid" => "Hj8rAI2HN48BAAAAAAAAAA==",
              "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48BAAAAAAAAAA==/",
              "_ts" => 1620141668,
              "id" => "d22d663e-6fa1-49af-98f8-df397f266999",
              "name" => "Test item here"
            },
            %{
              "_attachments" => "attachments/",
              "_etag" => "\"02003980-0000-0200-0000-60916f6d0000\"",
              "_rid" => "Hj8rAI2HN48CAAAAAAAAAA==",
              "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48CAAAAAAAAAA==/",
              "_ts" => 1620143981,
              "id" => "bef3c1f3-3f66-49a3-ba77-6e8d0e641664",
              "name" => "This is a test"
            }
          ]
        },
        count: 2,
        properties: %{
          continuation_token: nil,
          request_charge: "1",
          request_duration: "0.66"
        },
        resource_id: "Hj8rAI2HN48="
       }
      }

    Retrieve the first two documents from a container.

      iex> container = CosmosDbEx.Container.new("database", "container")
      iex> {:ok, response} = container |> CosmosDbEx.get_documents(2)
      {:ok,
        %CosmosDbEx.Response{
          body: %{
            "Documents" => [
              %{
                "_attachments" => "attachments/",
                "_etag" => "\"0200c45b-0000-0200-0000-609166640000\"",
                "_rid" => "Hj8rAI2HN48BAAAAAAAAAA==",
                "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48BAAAAAAAAAA==/",
                "_ts" => 1620141668,
                "id" => "d22d663e-6fa1-49af-98f8-df397f266999",
                "name" => "Test item here"
              },
              %{
                "_attachments" => "attachments/",
                "_etag" => "\"02003980-0000-0200-0000-60916f6d0000\"",
                "_rid" => "Hj8rAI2HN48CAAAAAAAAAA==",
                "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48CAAAAAAAAAA==/",
                "_ts" => 1620143981,
                "id" => "bef3c1f3-3f66-49a3-ba77-6e8d0e641664",
                "name" => "This is a test"
              }
            ]
          },
          count: 2,
          properties: %{
            continuation_token: %{
              "range" => %{"max" => "FF", "min" => ""},
              "token" => "Hj8rAI2HN48CAAAAAAAAAA=="
            },
            request_charge: "1",
            request_duration: "0.429"
          },
          resource_id: "Hj8rAI2HN48="
         }
        }


    A continuation of the example above.  Using the continuation token retrieves the next page of
    documents.  This can also be combined with `max_item_count` to restrict how many items are returned
    during continuation as well.

      iex> {:ok, response} = container |> CosmosDbEx.get_documents(response.properties.continuation_token)
        {:ok,
          %CosmosDbEx.Response{
            body: %{
              "Documents" => [
                %{
                  "_attachments" => "attachments/",
                  "_etag" => "\"82035043-0000-0200-0000-60a1bac30000\"",
                  "_rid" => "Hj8rAI2HN48DAAAAAAAAAA==",
                  "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48DAAAAAAAAAA==/",
                  "_ts" => 1621211843,
                  "id" => "2323490-23-23-3923493293",
                  "name" => "This is a test of the protocol"
                },
                %{
                  "_attachments" => "attachments/",
                  "_etag" => "\"8203015f-0000-0200-0000-60a1c47e0000\"",
                  "_rid" => "Hj8rAI2HN48FAAAAAAAAAA==",
                  "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48FAAAAAAAAAA==/",
                  "_ts" => 1621214334,
                  "id" => "ACME-HD-WOLF01234",
                  "location" => "Bottom of a cliff",
                  "name" => "ACME hair dryer"
                },
                %{
                  "_attachments" => "attachments/",
                  "_etag" => "\"5d00e34c-0000-0200-0000-60b41c140000\"",
                  "_rid" => "Hj8rAI2HN48GAAAAAAAAAA==",
                  "_self" => "dbs/Hj8rAA==/colls/Hj8rAI2HN48=/docs/Hj8rAI2HN48GAAAAAAAAAA==/",
                  "_ts" => 1622416404,
                  "id" => "TestDoc-2-1-3-2",
                  "location" => "Under da hill",
                  "name" => "Just another test document"
                }
              ]
            },
            count: 3,
            properties: %{
              continuation_token: nil,
              request_charge: "1",
              request_duration: "0.596"
            },
            resource_id: "Hj8rAI2HN48="
          }
        }

  """
  @spec get_documents(Container.t(), map()) ::
          {:ok
           | :bad_request
           | :conflict
           | :entity_too_large
           | :not_found
           | :storage_limit_reached
           | :unauthorized, CosmosDbEx.Response.t()}
  def get_documents(container, continuation_token)
      when is_struct(container) and
             is_map(continuation_token) do
    container
    |> get_documents(100, continuation_token)
  end

  @spec get_documents(Container.t(), integer(), map() | nil) ::
          {:ok
           | :bad_request
           | :conflict
           | :entity_too_large
           | :not_found
           | :storage_limit_reached
           | :unauthorized, CosmosDbEx.Response.t()}
  def get_documents(container, max_item_count \\ 100, continuation_token \\ nil)
      when is_struct(container) and
             is_integer(max_item_count) and
             max_item_count > 0 do
    container
    |> Documents.get_items(max_item_count, continuation_token)
  end

  @doc """
  Sends a query to Cosmos Db.

  ## Parameters

   - container: The container containing the database metadata.
   - query: The query contains the SQL query text.
   - params: A List of key/value pairs that correspond to values in the query.


  ### Query String and Params

  Notice the query string in the example below.  For each value that will be substituted by an entry
  in the params list, the key in the query string must be annotated with an '@' symbol.

  ## Example:

      iex> container = CosmosDbEx.Container.new("database", "container")
      iex> query_text = "SELECT * FROM ItemsContainer c WHERE c.id = @id and c.name = @name"
      iex> params = [{"id", "ACME-HD-WOLF01234"}, {"name", "ACME hair dryer"}]
      iex> CosmosDbEx.query(container, query_text, params)
      {:ok,
       %CosmosDbEx.Response{
         body: %{
           "Documents" => [
             %{
               "_attachments" => "attachments/",
               "_etag" => "\"8203015f-0000-0200-0000-60a1c47e0000\"",
               "_rid" => "AAarArAAAAAFAAAAAAAAAA==",
               "_ts" => 1621214334,
               "id" => "ACME-HD-WOLF01234",
               "location" => "Bottom of a cliff",
               "name" => "ACME hair dryer"
             }
           ]
         },
         count: 1,
         properties: %{
           continuation_token: nil,
           request_charge: "2.83",
           request_duration: "0.734"
         },
         resource_id: "AA8rAA2AN48="
       }
      }

  """
  @spec query(Container.t(), String.t(), list()) ::
          {:ok
           | :bad_request
           | :conflict
           | :entity_too_large
           | :not_found
           | :storage_limit_reached
           | :unauthorized, CosmosDbEx.Response.t()}
  def query(container, query_text, params)
      when is_struct(container) and
             is_binary(query_text) and
             is_list(params) do
    Documents.query(container, query_text, params)
  end

  @doc """
  Creates a new document in the specified database and container.

  Documents can be any struct or map that contain an :id field, or you can implement the
  `CosmosDbEx.Documents.Identifiable` protocol to customize the creation of a documents id.

  > NOTE:  You must implement the Jason.Encoder protocol for any struct that will be used as the
  > document being created.  You can do this by adding the following to your struct definition:

      @dervie {Jason.Encoder, only: [....]}
      defstruct ...

  Every request will return a tuple containing the status of the request as well as any information
  Cosmos Db returned in the body of the response. The only exception is when our call to the Rest
  API fails for a non-CosmosDb related issue

  Here are the tuple pairs returned for the following situations:

  * `{:ok, %CosmosDbEx.Response{}}` - The operation was successful.
  * `{:bad_request, %CosmosDbEx.Response{}}` - The JSON body is invalid.
  * `{:storage_limit_reached, %CosmosDbEx.Response{}}` - The operation could not be completed because
     the storage limit of the partition has been reached.
  * `{:conflict, %CosmosDbEx.Response{}}` - The ID provided for the new document has been taken by
     an existing document.
  * `{:entity_too_large, %CosmosDbEx.Response{}}` - The document size in the request exceeded the
     allowable document size.
  * `{:error, error}` - Any errors encountered by our http client that aren't related to CosmosDb.


  ## Examples

        iex> item = %{ name: "ACME hair dryer", id: "ACME-HD-WOLF01234", location: "Bottom of a cliff"}
        iex> container = CosmosDbEx.Container.new("database", "container")
        iex> container |> CosmosDbEx.create_document(item, item.name)
        {:ok,
         %CosmosDbEx.Response{
           body: %{
             "_attachments" => "attachments/",
             "_etag" => "00000000-0000-0000-0000-000000000000",
             "_rid" => "AAAAAAAAAAAAAAAAA==",
             "_self" => "dbs/AAAAAA==/colls/AAAAAAAAAAA=/docs/AAAAAAAAAAAAAAAAAAAAAA==/",
             "_ts" => 1620141668,
             "id" => "ACME-HD-WOLF01234",
             "location" => "Bottom of a cliff",
             "name" => "ACME hair dryer"
           },
           properties: %{
            request_charge: "6.29",
            request_duration: "5.328"
           }
          }
        }

  """
  @spec create_document(Container.t(), map(), String.t()) ::
          {:ok
           | :bad_request
           | :conflict
           | :entity_too_large
           | :not_found
           | :storage_limit_reached
           | :unauthorized, CosmosDbEx.Response.t()}
  def create_document(container, document, partition_key) do
    container
    |> Documents.create_item(document, partition_key)
  end
end
