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

  test "url_encode for string" do
    assert "%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F%3A%3B%3C%3D%3E%3F%40%5B%5C%5D%5E%60%7B%7C%7D" ==
             Utils.url_encode(" !\"#$%&'()*+,/:;<=>?@[\\]^`{|}")
  end

  test "url_encode for integer" do
    assert "123" == Utils.url_encode(123)
  end
end
