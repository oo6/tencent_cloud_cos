defmodule COS.Bucket do
  @moduledoc """
  存储桶（Bucket）是对象的载体，可理解为存放对象的“容器”，且该“容器”无容量上限。

  [腾讯云文档](https://cloud.tencent.com/document/product/436/13312)
  """

  alias COS.HTTPClient

  @doc """
  创建存储桶 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7738)

  ## 示例

      iex> COS.Bucket.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          "server", "tencent-cos",
          "data", "Tue, 29 Mar 2022 16:39:58 GMT",
          ...
        ],
        ...
      }}

      # 创建多 AZ 存储桶
      COS.Bucket.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        %{bucket_a_z_config: "MAZ"}
      )
  """
  @spec put(
          host :: binary(),
          config :: %{bucket_a_z_config: binary()} | nil,
          opts :: Tesla.Env.opts()
        ) ::
          Tesla.Env.t()
  def put(host, config \\ nil, opts \\ []) do
    body = if config, do: {:create_bucket_configuration, config}
    HTTPClient.request(method: :put, url: host, body: body, opts: opts)
  end
end
