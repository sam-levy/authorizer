defmodule User do
  use Authorizer.Types

  @fields [:name, :roles, :permissions]

  @enforce_keys @fields
  defstruct @fields

  @type t :: %__MODULE__{
          name: String.t(),
          roles: roles(),
          permissions: permissions()
        }
end
