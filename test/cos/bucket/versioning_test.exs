defmodule COS.Bucket.VersioningTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias COS.Bucket.Versioning

  test "unified response body while never enabled or suspended on the bucket" do
    mock(fn _ ->
      text("""
      <?xml version='1.0' encoding='utf-8' ?>
      <VersioningConfiguration/>
      """)
    end)

    assert {:ok, %{body: %{"status" => nil}}} =
             Versioning.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com")
  end
end
