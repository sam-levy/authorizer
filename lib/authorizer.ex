defmodule Authorizer do
  defmacro defpermit(call, do: expr) do
    {function_name, claim} =
      case Macro.decompose_call(call) do
        {function_name, [claim | _] = _args} -> {function_name, claim}
        _ -> raise ArgumentError, "invalid syntax in defpermit #{Macro.to_string(call)}"
      end

    quote do
      def unquote(call) do
        unquote(claim)
        |> validate_claim()
        |> set_action(unquote(function_name))
        |> validate_role()
        |> validate_permission()
        |> handle_result(unquote(expr))
      end

      def validate_claim(%Authorizer.Claim{} = claim), do: claim

      def validate_claim(_) do
        raise ArgumentError,
              "The first argument of defpermit should always be a %Authorizer.Claim{} struct"
      end

      def set_action(%Authorizer.Claim{action: nil} = claim, function_name) do
        %{claim | action: function_name}
      end

      def set_action(claim, _function_name), do: claim

      def validate_role(%Authorizer.Claim{} = claim, role \\ :user) do
        case Map.fetch(claim.roles, {claim.resource_id_key, claim.resource_id}) do
          {:ok, ^role} -> claim
          _ -> {:error, :unauthorized}
        end
      end

      def validate_permission(%Authorizer.Claim{} = claim) do
        with {:ok, resources} <- Map.fetch(claim.permissions, claim.action),
             {:ok, resource_ids} <- Map.fetch(resources, claim.resource_id_key),
             true <- Enum.member?(resource_ids, claim.resource_id) do
          claim
        else
          _ -> {:error, :unauthorized}
        end
      end

      def validate_permission(err), do: err

      def handle_result(%Authorizer.Claim{}, expr), do: expr
      def handle_result(err, _epr), do: err

      defoverridable validate_claim: 1,
                     set_action: 2,
                     validate_role: 1,
                     validate_role: 2,
                     validate_permission: 1,
                     handle_result: 2
    end
  end
end
