defmodule COS.UtilsTest do
  use ExUnit.Case, async: true

  alias COS.Utils

  test "undersocore nested map keys" do
    assert %{"foo" => %{"bar" => "Blah"}} ==
             Utils.underscore_keys(%{"Foo" => %{"Bar" => "Blah"}})
  end

  test "undersocore map keys in list" do
    assert %{"foo" => [%{"bar" => "Blah"}]} ==
             Utils.underscore_keys(%{"Foo" => [%{"Bar" => "Blah"}]})
  end
end
