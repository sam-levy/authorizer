defmodule Authorizer.Claim do
  use Authorizer.Types

  @required [:resource_id_key, :resource_id, :roles, :permissions]

  @enforce_keys @required
  defstruct [:action] ++ @required

  @type t :: %__MODULE__{
          action: action(),
          resource_id_key: resource_id_key(),
          resource_id: resource_id(),
          roles: roles(),
          permissions: permissions()
        }
end
