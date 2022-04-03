defmodule COS.ObjectTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias COS.Object

  describe "multi_delete" do
    test "unified response body while no error" do
      mock(fn _ ->
        text("""
        <?xml version='1.0' encoding='utf-8' ?>
        <DeleteResult>
          <Deleted>
            <Key>example.txt</Key>
            <DeleteMarker>true</DeleteMarker>
            <DeleteMarkerVersionId>foo_bar</DeleteMarkerVersionId>
          </Deleted>
        </DeleteResult>
        """)
      end)

      assert {:ok,
              %{
                body: %{
                  "deleted" => [
                    %{
                      "key" => "example.txt",
                      "delete_marker" => "true",
                      "delete_marker_version_id" => "foo_bar"
                    }
                  ],
                  "error" => []
                }
              }} =
               Object.multi_delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", %{
                 object: [%{key: "example.txt"}]
               })
    end

    test "unified response body while quiet or no deleted" do
      mock(fn _ ->
        text("""
        <?xml version='1.0' encoding='utf-8' ?>
        <DeleteResult>
          <Error>
            <Key>error.txt</Key>
            <Code>foo</Code>
            <Message>bar</Message>
          </Error>
        </DeleteResult>
        """)
      end)

      assert {:ok,
              %{
                body: %{
                  "deleted" => [],
                  "error" => [%{"key" => "error.txt", "code" => "foo", "message" => "bar"}]
                }
              }} =
               Object.multi_delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", %{
                 quiet: true,
                 object: [%{key: "error.txt"}]
               })
    end
  end
end
