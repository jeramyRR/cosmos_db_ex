defmodule CosmosDbEx.Auth do
  @moduledoc """
  Provides all necessary functionality to peform Cosmos Db Rest API calls with authorization.

  The general authorization methods were created using the Azure documentation located here:
  [Access control in the Azure Cosmos DB SQL API](https://docs.microsoft.com/en-us/rest/api/cosmos-db/access-control-on-cosmosdb-resources?redirectedfrom=MSDN)
  """

  @doc """
  Generates a hashed token signature for a master token that will be used for authorization of each
  request to the Cosmos Db api.

  ## Params

   - http_verb: A HTTP verb, such as GET, POST, PUT.

   - resource_type: Identifies the type of resource that the request is for.  Example: dbs, colls, docs.

   - resource_id: The identity of the resource that the request is directed at.  An example for a
   request for a collection would be: "dbs/MyDatabase/colls/MyCollection

   - date: The UTC date and time the message is being sent.  The date must conform to the format
   defined in [RFC 7231 Date/Time Formats](http://tools.ietf.org/html/rfc7231#section-7.1.1.1). Note
   that this must also be the date passed in the `x-ms-date` header.
   Example: "Tue, 01 Nov 1994 08:12:31 GMT".

   - key: This is the **Encoded** key for your Cosmos Db database. It is usually either the primary
   or secondary key that can be found in the `Keys` setting in your databases blade.  *Note: This
   key should never be saved and controlled in any repo.  The key should be retrieved from something
   like Azure Key Vault, or an environment variable.*

   - key_type: The type of key being used for authorization.  This will normally be "master".

   - token_version: The version of the token, or the format rather, being sent to Cosmos Db.  The
   current supported version is 1.0.


  ## Remarks

  I'm not really certain how much compute it takes to decode a Base64 encoded string, but there are
  actually Elixir libraries out there that drop down to 'C' just to make it faster.  If it turns out
  that constantly decoding the key hampers performance then we can see about possibly storing the
  decoded key in ETS to reduce compute a little bit.

  """
  def generate_auth_signature(
        http_verb,
        path,
        date,
        key,
        key_type \\ "master",
        token_version \\ "1.0"
      ) do
    verb = normalize_payload_part(http_verb)

    resource_type = build_resource_type(path)
    resource_link = build_resource_link(path)

    date = String.downcase(date)

    payload = "#{verb}\n#{resource_type}\n#{resource_link}\n#{date}\n\n"
    signature = get_signature(key, payload)
    token = "type=#{key_type}&ver=#{token_version}&sig=#{signature}"

    URI.encode_www_form(token)
  end

  defp build_resource_type(path) do
    path
    |> String.split("/")
    |> Enum.reverse()
    |> get_resource_type()
  end

  @resource_types ["dbs", "colls", "docs"]
  defp get_resource_type([h | _t]) when h in @resource_types, do: h
  defp get_resource_type([_h | t]), do: get_resource_type(t)

  defp build_resource_link(path) do
    path
    |> String.split("/")
    |> Enum.reverse()
    |> filter_resource_link()
    |> Enum.reverse()
    |> Enum.join("/")
  end

  defp filter_resource_link([h | t]) when h in @resource_types, do: t
  defp filter_resource_link(list), do: list

  defp get_signature(key, payload) do
    decoded_key = key |> Base.decode64!()

    :sha256
    |> hmac_fun(decoded_key, payload)
    |> Base.encode64()
  end

  defp normalize_payload_part(part) do
    part
    |> String.trim()
    |> String.downcase()
  end

  if Code.ensure_loaded?(:crypto) and function_exported?(:crypto, :mac, 4) do
    defp hmac_fun(digest, key, data), do: :crypto.mac(:hmac, digest, key, data)
  else
    defp hmac_fun(digest, key, data), do: :crypto.hmac(digest, key, data)
  end
end
