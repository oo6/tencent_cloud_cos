defmodule COS.Object.TaggingTest do
  use COS.DataCase, async: true

  alias COS.Object.Tagging

  describe "get" do
    test "return empty list when object no tag" do
      mock(fn _ ->
        xml("""
        <?xml version='1.0' encoding='utf-8' ?>
        <Tagging>
          <TagSet/>
        </Tagging>
        """)
      end)

      assert {:ok, %{body: %{"tag_set" => []}}} =
               Tagging.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt")
    end

    test "return list of tag when object has only one tag" do
      mock(fn _ ->
        xml("""
        <?xml version='1.0' encoding='utf-8' ?>
        <Tagging>
          <TagSet>
            <Tag>
              <Key>foo</Key>
              <Value>bar</Value>
            </Tag>
          </TagSet>
        </Tagging>
        """)
      end)

      assert {:ok, %{body: %{"tag_set" => [%{"key" => "foo", "value" => "bar"}]}}} =
               Tagging.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt")
    end
  end
end
