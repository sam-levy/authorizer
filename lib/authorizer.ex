defmodule Authorizer do
  defmacro defpermit(call, do: expr) do
    {function_name, claim} =
      case Macro.decompose_call(call) do
        {function_name, [claim | _] = _args} -> {function_name, claim}
        _ -> raise ArgumentError, "invalid syntax in defpermit #{Macro.to_string(call)}"
      end

    quote do
      import Authorizer

      def unquote(call) do
        unquote(claim)
        |> validate_claim()
        |> set_action(unquote(function_name))
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

      def validate_permission(%Authorizer.Claim{} = claim) do
        if can?(claim), do: claim, else: {:error, :unauthorized}
      end

      def validate_permission(err), do: err

      def handle_result(%Authorizer.Claim{}, expr), do: expr
      def handle_result(err, _epr), do: err

      defoverridable validate_claim: 1,
                     set_action: 2,
                     validate_permission: 1,
                     handle_result: 2
    end
  end

  alias Authorizer.Claim

  def can?(%Claim{} = claim, action) when is_atom(action) do
    can?(%{claim | action: action})
  end

  def can?(%Claim{action: nil}) do
    raise ArgumentError,
          "The action should be passed as second argument when is not present in the %Authorizer.Claim{} struct"
  end

  def can?(%Claim{action: action} = claim) when is_atom(action) do
    with true <- has_any_role?(claim),
         {:ok, resources} <- Map.fetch(claim.permissions, claim.action),
         {:ok, resource_ids} <- Map.fetch(resources, claim.resource_id_key),
         true <- Enum.member?(resource_ids, claim.resource_id) do
      true
    else
      _ -> false
    end
  end

  defp has_any_role?(%Claim{} = claim) do
    case Map.fetch(claim.roles, {claim.resource_id_key, claim.resource_id}) do
      {:ok, _role} -> true
      _ -> false
    end
  end
end
