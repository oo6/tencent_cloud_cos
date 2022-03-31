defmodule COS.HTTPClientTest do
  use ExUnit.Case, async: true

  alias COS.HTTPClient

  test "nested map to xml" do
    xml = """
    <RootKey>
      <Foo>
        <Bar>blah</Bar>
      </Foo>
    </RootKey>
    """

    assert String.replace(xml, ~r/(\n|\s)/, "") ==
             HTTPClient.map_to_xml({:root_key, %{foo: %{bar: "blah"}}})
  end

  test "list to xml" do
    xml = """
    <RootKey>
      <Foo>
        <Bar>blah</Bar>
        <Bar>buzz</Bar>
      </Foo>
    </RootKey>
    """

    assert String.replace(xml, ~r/(\n|\s)/, "") ==
             HTTPClient.map_to_xml({:root_key, %{foo: %{bar: ["blah", "buzz"]}}})
  end
end
