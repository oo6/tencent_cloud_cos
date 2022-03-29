defmodule COS.Object do
  @moduledoc """
  对象（Object）是对象存储的基本单元，可理解为任何格式类型的数据，例如图片、文档和音视频文件等。

  [腾讯云文档](https://cloud.tencent.com/document/product/436/13324)
  """

  alias COS.HTTPClient

  @doc ~S"""
  简单上传对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7749)

  可以上传一个对象至指定存储桶中，该操作需要请求者对存储桶有 WRITE 权限。
  最大支持上传不超过5GB的对象，5GB以上对象请使用分块上传(Todo)或高级接口(Todo)上传。

  ## 示例

      iex> COS.Object.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "content")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          "server", "tencent-cos",
          "data", "Tue, 29 Mar 2022 16:39:58 GMT",
          ...
        ],
        ...
      }}

      # 设置传对象的内容类型
      COS.Object.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        "example.json",
        "{\"key\":\"value\"}",
        "content-type": "application-json"
      )

      # 设置 HTTP 响应的超时时间
      COS.Object.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        "example.txt",
        "content",
        [],
        adapter: [recv_timeout: 30_000]
      )

      # 创建“文件夹”
      COS.Object.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example/", "")
  """
  @spec put(
          host :: binary(),
          key :: binary(),
          content :: binary(),
          headers :: [{binary(), binary()}],
          opts :: Tesla.Env.opts()
        ) :: Tesla.Env.t()
  def put(host, key, content, headers \\ [], opts \\ []) do
    HTTPClient.request(
      method: :put,
      url: host <> "/" <> key,
      body: content,
      headers: headers,
      opts: opts
    )
  end

  @doc """
  上传本地文件

  ## 示例

      iex> COS.Object.put_from_file("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "./example.txt")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          "server", "tencent-cos",
          "data", "Tue, 29 Mar 2022 16:39:58 GMT",
          ...
        ],
        ...
      }}
  """
  @spec put_from_file(
          host :: binary(),
          key :: binary(),
          path :: binary(),
          headers :: [{binary(), binary()}],
          opts :: Tesla.Env.opts()
        ) :: Tesla.Env.t()
  def put_from_file(host, key, path, headers \\ [], opts \\ []) do
    put(host, key, File.read!(path), headers, opts)
  end

  @doc """
  复制对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/10881)

  创建一个已存在 COS 的对象的副本，即将一个对象从源路径（对象键）复制到目标路径（对象键）。
  建议对象大小为1M到5G，超过5G的对象请使用分块上传(Todo)。

  ## 示例

      iex> COS.Object.copy(
             "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
             "destination.txt",
             "other-bucket-1250000000.cos.ap-shanghai.myqcloud.com/source.txt"
           )
      {:ok, %Tesla.Env{
        body: %{
          "crc64" => "1791993320000000000",
          "e_tag" => "\"6ae33dfd6c0c9fa03b77f75xxxxxxxxx\"",
          "last_modified" => "2022-03-29T17:20:24Z"
        },
        headers: [
          "server", "tencent-cos",
          "data", "Tue, 29 Mar 2022 16:39:58 GMT",
          ...
        ],
        ...
      }}
  """
  @spec copy(
          host :: binary(),
          key :: binary(),
          source :: binary(),
          headers :: [{binary(), binary()}],
          opts :: Tesla.Env.opts()
        ) :: Tesla.Env.t()
  def copy(host, key, source, headers \\ [], opts \\ []) do
    HTTPClient.request(
      method: :put,
      url: host <> "/" <> key,
      headers: [{"x-cos-copy-source", source} | headers],
      opts: [{:result_key, "copy_object_result"} | opts]
    )
  end

  @doc """
  查询对象元数据 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7745)
  """
  @spec head(
          host :: binary(),
          key :: binary(),
          headers :: [{binary(), binary()}],
          opts :: Tesla.Env.opts()
        ) :: Tesla.Env.t()
  def head(host, key, headers \\ [], opts \\ []) do
    HTTPClient.request(method: :head, url: host <> "/" <> key, headers: headers, opts: opts)
  end

  @doc """
  检查对象是否存在

  ## 示例

      iex> COS.Object.exists?("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt")
      true

      iex> COS.Object.exists?("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example/")
      true

      iex> COS.Object.exists?("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "missing.txt")
      false
  """
  @spec exists?(host :: binary(), key :: binary()) :: boolean()
  def exists?(host, key) do
    with {:ok, _response} <- head(host, key) do
      true
    else
      _ -> false
    end
  end
end
