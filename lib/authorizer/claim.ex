defmodule Authorizer.Claim do
  @required [:resource_id_key, :resource_id, :roles, :permissions]

  @enforce_keys @required
  defstruct [:action] ++ @required

  @typedoc "A struct representing the claim for an authorized action."
  @type t :: %__MODULE__{
          action: action(),
          resource_id_key: resource_id_key(),
          resource_id: resource_id(),
          roles: roles(),
          permissions: permissions()
        }

  @typedoc """
  The key to identify the resource that the user needs to have permission.
  An alias for `atom()`.
  Eg.: `:company_id`.
  """
  @type resource_id_key :: atom()

  @typedoc "The ID of the resource that the user needs to have permission."
  @type resource_id :: binary() | integer()

  @typedoc "The user role. An alias for `atom()`."
  @type role :: atom()

  @typedoc "The name of the action to be permitted. An alias for `atom()`."
  @type action :: atom()

  @typedoc """
  A map with a two element tuple (resource FK field and resource ID) as key
  and a role as value.
  """
  @type roles :: %{{resource_id_key(), resource_id()} => role()}

  @typedoc """
  A map representing which actions the user can execute for each target resource.
  The value is a map whith the resource field as key and a list of resource IDs as value.
  """
  @type permissions :: %{action() => %{resource_id_key() => [resource_id()]}}
end
