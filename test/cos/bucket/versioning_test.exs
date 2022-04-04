defmodule COS.Bucket.VersioningTest do
  use COS.DataCase, async: true

  alias COS.Bucket.Versioning

  test "unified response body while never enabled or suspended on the bucket" do
    mock(fn _ ->
      xml("""
      <?xml version='1.0' encoding='utf-8' ?>
      <VersioningConfiguration/>
      """)
    end)

    assert {:ok, %{body: %{"status" => nil}}} =
             Versioning.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com")
  end
end
