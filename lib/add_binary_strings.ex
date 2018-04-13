defmodule AddBinaryStrings do
  @moduledoc """
  Adds two "binary" strings with 0s and/or 1s properly
  For example string "001" plus string "011" equals string "100"
  """

  require Logger

  @doc "Adds two non-empty strings which contain only 0s and 1s"
  @spec add(binary(), binary()) :: binary()

  def add(s1, s2)
      when is_binary(s1) and is_binary(s2) and byte_size(s1) > 0 and byte_size(s2) > 0 do
    # Ensure params are well formed, shrinking any leading zeros as necessary
    {:ok, s1, s2} = validate_helper(s1, s2)

    # Reverse codepoints list so that we start "adding" from what was 
    # the right most digit first, similiar to manual human addition
    a = s1 |> String.codepoints() |> Enum.reverse()
    b = s2 |> String.codepoints() |> Enum.reverse()

    # Determine the size difference between strings so we can pad them making them equal
    # We pad with a list of "0"s to the shorter list

    len_a = length(a)
    len_b = length(b)

    pad_size = Kernel.abs(len_a - len_b)
    pad = Stream.cycle(["0"]) |> Enum.take(pad_size)

    # We zip the two equal sized lists (after padding), so that its
    # easy to perform a reduce

    # Include lengths so we don't have to compute them again
    zipped = zip_pad(a, b, len_a, len_b, pad)

    Logger.debug("zipped is #{inspect(zipped)}")

    # We reduce the zipped list, using two accumulators
    # one being the new summed bitwise list, the other the current carry value

    {list, carry} =
      Enum.reduce(zipped, {[], 0}, fn {sx, sy}, {l_acc, c_acc} ->
        # Converting to integer allows us to leverage the special
        # relationship depicted in the table below
        x = String.to_integer(sx)
        y = String.to_integer(sy)

        sum = x + y + c_acc

        # Table
        #                         next
        #                    val  c_acc
        # x, y, c_acc   sum   %2  /2
        # 0  0  0       0     0   0
        # 0  0  1       1     1   0
        # 0  1  0       1     1   0
        # 0  1  1       2     0   1
        # 1  0  0       1     1   0
        # 1  0  1       2     0   1
        # 1  1  1       3     1   1

        Logger.debug("Sum is #{sum}")

        # The bitwise sum value is just the additive integer sum mod 2
        # Convert to string using interpolation
        value = "#{Integer.mod(sum, 2)}"

        # Dividing the additive integer sum by 2 gives us the carry over
        c_acc = Kernel.div(sum, 2)

        # Prepend value to list
        l_acc = [value] ++ l_acc

        Logger.debug("new acc is list: #{inspect(l_acc)}, carry: #{c_acc}")

        # Return accumulated bitwise summed base2 list as well as
        # current integer carry value
        {l_acc, c_acc}
      end)

    # Ensure we handle the edge case of when there is a carry in the last iteration
    # Simply prepend to list

    list =
      cond do
        1 == carry ->
          ["1"] ++ list

        true ->
          list
      end

    # Ensure we transform back to String form :)
    list |> Enum.join()
  end

  # Shrink help function
  # eliminates leading zeros
  # if the string contains only "0", reduce down to a single "0"

  # Similiar idea to String.replace_leading
  def shrink(s) when is_binary(s) do
    # If we walk through string codepoints and we haven't seen a "1" just "0"s
    # don't store the "0"s in the new list until we've seen a one
    {l, _} =
      Enum.reduce(String.codepoints(s), {[], false}, fn x, {list_acc, seen_one_acc} ->
        case x do
          "0" when false == seen_one_acc -> {list_acc, seen_one_acc}
          "1" when false == seen_one_acc -> {["1"] ++ list_acc, true}
          x when true == seen_one_acc -> {[x] ++ list_acc, seen_one_acc}
        end
      end)

    # Notice if we have a list of just "0"s we will end up with [], put a single "0"
    l = if l == [], do: ["0"], else: l

    # Ensure we reverse the list and then join back to create a String
    l |> Enum.reverse() |> Enum.join()
  end

  # Validate helper to ensure "binary" strings are properly formed
  defp validate_helper(s1, s2) do
    # Validate that we have a correctly formed string of just 0 and 1 strings
    flag =
      Enum.all?(String.codepoints(s1 <> s2), fn x ->
        MapSet.member?(MapSet.new(["0", "1"]), x)
      end)

    # raise Error if improper params
    case flag do
      true ->
        # Eliminate the leading zeros
        s1 = shrink(s1)
        s2 = shrink(s2)
        {:ok, s1, s2}

      false ->
        msg = "Strings must have values of only 0s and 1s.  User provided strings #{s1} and #{s2}"
        raise ArgumentError, message: msg
    end
  end

  # Convenience helper functions for padding properly
  defp zip_pad(a, b, len_a, len_b, pad) when len_a > len_b, do: Enum.zip(a, b ++ pad)
  defp zip_pad(a, b, len_a, len_b, pad) when len_b > len_a, do: Enum.zip(a ++ pad, b)
  defp zip_pad(a, b, len_a, len_b, _pad) when len_a == len_b, do: Enum.zip(a, b)
end
