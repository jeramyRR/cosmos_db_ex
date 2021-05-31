# cosmos_db_ex

This (unofficial) client library enables client applications targeting Elixir to connect to 
[Azure Cosmos DB](https://azure.microsoft.com/services/cosmos-db/) via the SQL REST API.

Most if not all of this libraries functionality is accessible from the `CosmosDbEx` module.

## Notice

This library is definitely in alpha stage.  There are no optimizations, and there are probably a
whole lot of areas that can be improved or changed completely.

I'm looking for any and all feedback: good, bad, or ugly.


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


## Status

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/tterb/atomic-design-ui/blob/master/LICENSEs) ![main build status](https://github.com/jeramyRR/cosmos_db_ex/actions/workflows/elixir.yml/badge.svg)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `cosmos_db_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cosmos_db_ex, "~> 0.1.0"}
  ]
end
```

## Usage:

Right now this library only implements the very basics needed to create a document and to retrieve
documents.  When I say 'basics' I mean only the basics.  So far there are only the following functions
available:

  *`get_document`: Retreives a document by it's id and partition key.

  *`get_documents`: Retrieves all documents in a container.

  *`query`: Gives you an additional option to write your own query to send to CosmosDb.  This is
  probably going to be your go-to function.

  *`create_document` - Create a document, in a container, using a Map and partition key.

### Containers

Everything requires a container (could also be called "collection").  A container is nothing more
than a struct with the database name and container name.  This is something that could probably be
done better, and may change in a future version.

Please see the docs at hex.pm for examples: [`cosmos_db_ex`](http://hexdocs.pm/cosmos_db_ex)

## Road Map (TODOs):

  As this is an early version, there is a boat load of work that still needs to be done.  The next
  versions will concentrate on the following:

  * Update create_document to work with `structs` as well as `maps`.
  
  * Add the ability to create new database and containers on startup, if they don't already exist.
  
  * Add Upsert.

  * Add ability to set consistency levels.

  * Add ability to use session tokens.
