defmodule COS.BucketTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

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
end
