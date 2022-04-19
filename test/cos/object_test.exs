defmodule COS.ObjectTest do
  use COS.DataCase, async: true

  alias COS.Object

  describe "multi_delete" do
    test "unified response body while no error" do
      mock(fn _ ->
        xml("""
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
        xml("""
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

  describe "get_presigned_url" do
    test "encode key" do
      assert Object.get_presigned_url(
               "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
               "你好.txt"
             ) =~ "%E4%BD%A0%E5%A5%BD.txt"
    end

    test "encode nested key keep /" do
      assert Object.get_presigned_url(
               "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
               "你好/世界.txt"
             ) =~ "%E4%BD%A0%E5%A5%BD/%E4%B8%96%E7%95%8C.txt"
    end
  end
end
