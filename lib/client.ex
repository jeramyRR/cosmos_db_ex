defmodule CosmosDbEx.Client do
  @moduledoc """


  """
  alias CosmosDbEx.Response
  alias CosmosDbEx.Client.{Container, Documents}

  @doc """
  Retrieve a document by it's document id and partition key.

  # Examples
    iex> container = CosmosDbEx.Client.Container.new("database", "container")
    iex> item_id = "00000000-0000-0000-0000-000000000000"
    iex> partition_key = item_id
    iex> CosmosDbEx.Client.get_document(container, item_id, partition_key)
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
      request_charge: "1",
      request_duration: "0.585"
    }}

  """
  def get_document(container, id, partition_key) when is_struct(container) do
    container
    |> Documents.get_item(id, partition_key)
  end

  def get_documents(container, continuation_token)
      when is_struct(container) and
             is_map(continuation_token) do
    container
    |> get_documents(100, continuation_token)
  end

  def get_documents(container, max_item_count \\ 100, continuation_token \\ nil)
      when is_struct(container) and
             is_integer(max_item_count) and
             max_item_count > 0 do
    container
    |> Documents.get_items(max_item_count, continuation_token)
  end

  @doc """
  Creates a new document in the specified database and container.

  Documents can be any struct that implements the CosmosDbEx.Client.Documents.Identifiable protocol,
  or any struct or map that contains an id field.  The Identifiable protocol contains a single
  function that must be implemented, called get_id().  You can return a string in any format to
  represent the id given to CosmosDb.

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
  * `{:error, error} - Any errors encountered by our http client that aren't related to CosmosDb.


  # Examples

    iex> item = %{ name: "ACME hair dryer", id: "ACME-HD-WOLF01234", location: "Bottom of a cliff"}
    iex> container = CosmosDbEx.Client.Container.new("database", "container")
    iex> container |> CosmosDbEx.Client.create_document(item, item.name)
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
       request_charge: "6.29",
       request_duration: "5.328"
     }}

  """
  def create_document(container, document, partition_key) do
    container
    |> Documents.create_item(document, partition_key)
  end
end
