defmodule AddBinaryStringsTest do
  use ExUnit.Case, async: true

  alias AddBinaryStrings, as: ABS

  @base 2

  test "an empty string as a value" do
    x = ""
    y = "001"

    assert catch_error(ABS.add(x, y)) == :function_clause
  end

  test "a string which doesn't contain base 2 values" do
    x = "01"
    y = "123"

    assert catch_error(ABS.add(x, y)) == %ArgumentError{
             message:
               "Strings must have values of only 0s and 1s.  User provided strings 01 and 123"
           }
  end

  test "strings of same size" do
    x = "001"
    y = "011"

    # Sum should be 100
    verify_sum = add_check(x, y)
    "100" = verify_sum

    assert verify_sum == ABS.add(x, y)
  end

  test "strings of different sizes" do
    x = "1101"
    y = "100"

    # Sum should be 10001
    verify_sum = add_check(x, y)
    "10001" = verify_sum
    assert verify_sum == ABS.add(x, y)

    # Flip the order
    verify_sum = add_check(y, x)
    "10001" = verify_sum
    assert verify_sum == ABS.add(y, x)
  end

  test "no carry example" do
    x = "1001"
    y = "0100"

    # Sum should be 1101
    verify_sum = add_check(x, y)
    "1101" = verify_sum
    assert verify_sum == ABS.add(x, y)
  end

  test "cascading carries" do
    x = "101"
    y = "011"

    # Sum should be 1000
    verify_sum = add_check(x, y)
    "1000" = verify_sum
    assert verify_sum == ABS.add(x, y)
  end

  # Helper function
  def add_check(x, y) when is_binary(x) and is_binary(y) do
    val_x = String.to_integer(x, @base)
    val_y = String.to_integer(y, @base)

    Integer.to_string(val_x + val_y, @base)
  end
end
