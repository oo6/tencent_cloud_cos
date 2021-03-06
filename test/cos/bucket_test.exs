defmodule COS.BucketTest do
  use COS.DataCase, async: true

  alias COS.Bucket

  test "put az bucket" do
    body =
      """
      <CreateBucketConfiguration>
        <BucketAZConfig>MAZ</BucketAZConfig>
      </CreateBucketConfiguration>
      """
      |> String.replace(~r/(\n|\s)/, "")

    mock(fn %{body: ^body} -> text("") end)

    assert {:ok, _} =
             Bucket.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
               body: %{bucket_a_z_config: "MAZ"}
             )
  end

  test "handling list objects return value formats" do
    mock(fn %{query: %{"max-keys": 1000}} ->
      xml("""
      <?xml version='1.0' encoding='utf-8' ?>
      <ListBucketResult>
        <Contents>
          <Key>foo/</Key>
          <LastModified>2022-04-04T11:40:35.000Z</LastModified>
          <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
          <Size>0</Size>
          <Owner>
            <ID>blah</ID>
            <DisplayName>blah</DisplayName>
          </Owner>
          <StorageClass>STANDARD</StorageClass>
        </Contents>
        <Contents>
          <Key>foo/bar.txt</Key>
          <LastModified>2022-04-04T11:40:48.000Z</LastModified>
          <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
          <Size>1024</Size>
          <Owner>
          <ID>blah</ID>
          <DisplayName>blah</DisplayName>
          </Owner>
          <StorageClass>STANDARD</StorageClass>
        </Contents>
        <Name>bucket-1250000000</Name>
        <IsTruncated>false</IsTruncated>
        <MaxKeys>1000</MaxKeys>
        <Prefix/>
        <Marker/>
        <NextMarker/>
      </ListBucketResult>
      """)
    end)

    assert {:ok,
            %{
              body: %{
                "contents" => [
                  %{"key" => "foo/", "size" => 0},
                  %{"key" => "foo/bar.txt", "size" => 1024}
                ],
                "is_truncated" => false,
                "max_keys" => 1000
              }
            }} =
             Bucket.list_objects("https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
               query: %{max_keys: 1000}
             )
  end

  test "list objects return error when no such bucket" do
    mock(fn _ ->
      xml(
        """
        <?xml version='1.0' encoding='utf-8' ?>
        <Error>
          <Code>NoSuchBucket</Code>
          <Message>The specified bucket does not exist.</Message>
          <Resource>invalid-bucket.cos.ap-beijing.myqcloud.com</Resource>
          <RequestId>NjI0ZDM4ZDlfNWRiM2IxMDlfMjlmM2NfMWFjYmVkYQ==</RequestId>
          <TraceId>OGVmYzZiMmQzYjA2OWNhODk0NTRkMTBiOWVmMDAxODc1NGE1MWY0MzY2NTg1MzM1OTY3MDliYzY2YTQ0ZThhMGJkZTk0YzA5YWMzNTJkMGZjNDgzNjQ5NTcyMmI4Mzdk</TraceId>
        </Error>
        """,
        status: 404
      )
    end)

    assert {:error, %{body: %{"code" => "NoSuchBucket"}}} =
             Bucket.list_objects("https://invalid-bucket.cos.ap-beijing.myqcloud.com")
  end

  test "handling list objects with versions return value formats" do
    mock(fn %{query: %{"max-keys": 1000}} ->
      xml("""
      <ListVersionsResult>
        <Version>
          <Key>foo</Key>
          <VersionId>MTg0NDUwOTQ5ODUyOTk0MjEwNzY</VersionId>
          <IsLatest>true</IsLatest>
          <LastModified>2022-04-04T16:06:50.000Z</LastModified>
          <ETag>&quot;310dcbbf4cce62f762a2aaa148d556bd&quot;</ETag>
          <Size>2</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
            <ID>blah</ID>
            <DisplayName>blah</DisplayName>
          </Owner>
        </Version>
        <Version>
          <Key>foo</Key>
          <VersionId>null</VersionId>
          <IsLatest>false</IsLatest>
          <LastModified>2022-04-04T15:59:17.000Z</LastModified>
          <ETag>&quot;c4ca4238a0b923820dcc509a6f75849b&quot;</ETag>
          <Size>1</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
            <ID>blah</ID>
            <DisplayName>blah</DisplayName>
          </Owner>
        </Version>
        <Version>
          <Key>bar</Key>
          <VersionId>MTg0NDUwOTQ5ODUyODM1NDE1NDc</VersionId>
          <IsLatest>true</IsLatest>
          <LastModified>2022-04-04T16:07:06.000Z</LastModified>
          <ETag>&quot;c4ca4238a0b923820dcc509a6f75849b&quot;</ETag>
          <Size>1</Size>
          <StorageClass>STANDARD</StorageClass>
          <Owner>
            <ID>blah</ID>
            <DisplayName>blah</DisplayName>
          </Owner>
        </Version>
        <Name>bucket-1250000000</Name>
        <IsTruncated>false</IsTruncated>
        <MaxKeys>1000</MaxKeys>
        <Prefix/>
        <KeyMarker/>
        <VersionIdMarker/>
      </ListVersionsResult>
      """)
    end)

    assert {:ok,
            %{
              body: %{
                "version" => [
                  %{
                    "key" => "foo",
                    "is_latest" => true,
                    "size" => 2,
                    "version_id" => "MTg0NDUwOTQ5ODUyOTk0MjEwNzY"
                  },
                  %{
                    "key" => "foo",
                    "is_latest" => false,
                    "size" => 1,
                    "version_id" => nil
                  },
                  %{
                    "key" => "bar",
                    "is_latest" => true,
                    "size" => 1,
                    "version_id" => "MTg0NDUwOTQ5ODUyODM1NDE1NDc"
                  }
                ],
                "is_truncated" => false,
                "max_keys" => 1000
              }
            }} =
             Bucket.list_objects_with_versions(
               "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
               query: %{max_keys: 1000}
             )
  end
end
