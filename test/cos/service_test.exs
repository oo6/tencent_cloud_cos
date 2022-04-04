defmodule COS.ServiceTest do
  use COS.DataCase, async: true

  alias COS.Service

  describe "get" do
    test "return empty list when no buckets" do
      mock(fn _ ->
        xml("""
        <ListAllMyBucketsResult>
          <Buckets/>
          <Owner>
            <ID>qcs::cam::uin/foo:uin/foo</ID>
            <DisplayName>foo</DisplayName>
          </Owner>
        </ListAllMyBucketsResult>
        """)
      end)

      assert {:ok, %{body: %{"buckets" => []}}} =
               Service.list_buckets("https://service.cos.myqcloud.com")
    end

    test "return list when has only one bucket" do
      mock(fn _ ->
        xml("""
        <ListAllMyBucketsResult>
          <Buckets>
            <Bucket>
              <Name>foo</Name>
              <Location>ap-shanghai</Location>
              <CreationDate>2022-04-03T13:17:24Z</CreationDate>
            </Bucket>
          </Buckets>
          <Owner>
            <ID>qcs::cam::uin/foo:uin/foo</ID>
            <DisplayName>foo</DisplayName>
          </Owner>
        </ListAllMyBucketsResult>
        """)
      end)

      assert {:ok, %{body: %{"buckets" => [%{"name" => "foo"}]}}} =
               Service.list_buckets("https://service.cos.myqcloud.com")
    end
  end
end
