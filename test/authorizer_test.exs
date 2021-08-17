defmodule AuthorizerTest do
  use ExUnit.Case
  doctest Authorizer

  alias Authorizer.Claim

  defmodule ExcitedGreeter do
    def say_loud_hello(name) do
      "HELLO #{String.upcase(name)}!!!"
    end
  end

  defmodule Greeter do
    import Authorizer

    defpermit(say_hi(claim), do: "Hi!")

    defpermit say_hello(claim, name) do
      "Hello #{name}!"
    end

    defpermit say_goodbye(claim, name) do
      "Goodbye #{name}!"
    end

    defpermit shout_hello(claim, name) do
      ExcitedGreeter.say_loud_hello(name)
    end
  end

  describe "defpermit" do
    test "executes block when permitted" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hi: %{company_id: [company_id]},
        say_hello: %{company_id: [company_id]},
        say_goodbye: %{company_id: [company_id]},
        shout_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hi(claim) == "Hi!"
      assert Greeter.say_hello(claim, "Bugs Bunny") == "Hello Bugs Bunny!"
      assert Greeter.say_goodbye(claim, "Elmer") == "Goodbye Elmer!"
      assert Greeter.shout_hello(claim, "Daffy Duck") == "HELLO DAFFY DUCK!!!"
    end

    test "executes block when permitted action is in Claim struct" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        greet: %{company_id: [company_id]}
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

    test "when the resource id is not in roles" do
      company_id = "company_id"

      roles = %{
        {:company_id, "another_company_id"} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_hello(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when the resource id key is not in roles" do
      company_id = "company_id"

      roles = %{
        {:organization_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
      }

      claim = %Claim{
        resource_id_key: :company_id,
        resource_id: company_id,
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
        resource_id: company_id,
        roles: roles,
        permissions: permissions
      }

      assert Greeter.say_goodbye(claim, "Bugs Bunny") == {:error, :unauthorized}
    end

    test "when there is no permission for the action in Claim struct" do
      company_id = "company_id"

      roles = %{
        {:company_id, company_id} => :user
      }

      permissions = %{
        say_hello: %{company_id: [company_id]}
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

    test "when permissions is empty" do
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

    test "when there is no permission for the claimed resource id key" do
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

    test "when first argument is not a Claim struct" do
      assert_raise ArgumentError,
                   "The first argument of defpermit should always be a %Authorizer.Claim{} struct",
                   fn ->
                     Greeter.say_hello(%{}, "Bugs Bunny")
                   end
    end
  end
end
