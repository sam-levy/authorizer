defmodule Greeter do
  import Authorizer

  def hello(name) do
    IO.puts("Hi! #{name}")
  end

  defpermit greet(claim, name) do
    hello(name)
  end

  defpermit say_goodbye(claim, title, name) do
    IO.puts("Good bye #{title} #{name}")
  end
end
