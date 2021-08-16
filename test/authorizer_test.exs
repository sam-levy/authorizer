defmodule AuthorizerTest do
  use ExUnit.Case
  doctest Authorizer

  alias Authorizer.Claim

  defmodule ExcitedGreeter do
    def say_loud_hello(name) do
      "HELLO #{String.upcase(name)}!!!"
    end

    def say_loud_goodbye(name) do
      "GOODBYE #{String.upcase(name)}!!!"
    end
  end

  defmodule Greeter do
    import Authorizer

    defpermit say_hello(claim, name) do
      "Hello #{name}!"
    end

    defpermit say_goodbye(claim, name) do
      "Goodbye #{name}!"
    end

    # defpermit say_loud_hello(claim, name), to: ExcitedGreeter

    # defpermit shout_goodbye(claim, name), to: ExcitedGreeter, as: :say_loud_goodbye
  end

  describe "defpermit" do
    test "executes block when permitted" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]},
        say_goodbye: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == "Hello Bugs Bunny!"
      assert Greeter.say_goodbye(claim, "Elmer") == "Goodbye Elmer!"
    end

    test "executes block when permitted action is in the claim" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        greet: %{company_id: [company_id]},
      }

      claim = %Claim{
        action: :greet,
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == "Hello Bugs Bunny!"
    end

    test "when there is no permission" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{}

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when there is no permission for the claimed resource id" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: "another_company_id",
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when there is no permission for the claimed resource" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :restaurant_id,
        resource_id: "restaurant_id",
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when there is no permission for the action" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id:  company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_goodbye(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when permitted action in the claim is different" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]},
      }

      claim = %Claim{
        action: :say_goodbye,
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == {:error, :unauthorized}
    end
  end
end
