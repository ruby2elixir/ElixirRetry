defmodule Retry do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Retry

      defmacro retry({ :in, _, [retries, sleep] }, do: block) do
        quote do
          run = fn(attempt, self) ->
            if attempt <= unquote(retries) do
              IO.puts "Attempt #{attempt}"

              try do
                case unquote(block) do
                  {:error, _} -> 
                    :timer.sleep(unquote(sleep))
                    self.(attempt + 1, self)
                end
              rescue
                e in RuntimeError -> 
                  :timer.sleep(unquote(sleep))
                  self.(attempt + 1, self)
              end
            else
              IO.puts "Giving up"
              unquote(block)
            end
          end

          run.(1, run)
        end
      end

      defmacro backoff(timeout, do: block) do
        quote do
          run = fn(attempt, self) ->
            # http://dthain.blogspot.com.au/2009/02/exponential-backoff-in-distributed.html
            sleep = :erlang.round((1 + :random.uniform) * 10 * :math.pow(2, attempt))
            IO.puts "Next sleep: #{sleep}"

            if sleep <= unquote(timeout) do
              IO.puts "Attempt #{attempt}"

              try do
                case unquote(block) do
                  {:error, _} -> 
                    :timer.sleep(sleep)
                    self.(attempt + 1, self)
                end
              rescue
                e in RuntimeError -> 
                  :timer.sleep(sleep)
                  self.(attempt + 1, self)
              end
            else
              IO.puts "Giving up"
              unquote(block)
            end
          end

          run.(1, run)
        end
      end
    end
  end
end