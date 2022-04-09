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
          {"server", "tencent-cos"},
          {"data", "Tue, 29 Mar 2022 16:39:58 GMT"},
          ...
        ],
        ...
      }}

      # 设置传对象的内容类型
      COS.Object.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        "example.json",
        "{\"key\":\"value\"}",
        headers: [{"content-type", "application-json"}]
      )

      # 设置 HTTP 响应的超时时间
      COS.Object.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        "example.txt",
        "content",
        tesla_opts: [adapter: [recv_timeout: 30_000]]
      )

      # 创建“文件夹”
      COS.Object.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example/", "")
  """
  @spec put(
          host :: binary(),
          key :: binary(),
          content :: binary(),
          opts :: [headers: Tesla.Env.headers(), tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def put(host, key, content, opts \\ []) do
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :put,
      url: host <> "/" <> key,
      body: content,
      headers: headers,
      opts: opts[:tesla_opts]
    )
  end

  @doc """
  上传本地文件

  ## 示例

      iex> COS.Object.put_from_file("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "./example.txt")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          {"server", "tencent-cos"},
          {"data", "Tue, 29 Mar 2022 16:39:58 GMT"},
          ...
        ],
        ...
      }}
  """
  @spec put_from_file(
          host :: binary(),
          key :: binary(),
          path :: binary(),
          opts :: [headers: Tesla.Env.headers(), tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def put_from_file(host, key, path, opts \\ []) do
    put(host, key, File.read!(path), opts)
  end

  @doc """
  追加上传对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7741)

  ## 示例

      iex> COS.Object.append("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", 0, "hello")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          {"x-cos-content-sha1", "5d41402abc4b2a76b9719d911017c592"},
          {"x-cos-next-append-position", "5"},
          ...
        ],
        ...
      }}

      iex> COS.Object.append("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", 5, " world")
      {:ok, %Tesla.Env{
        body: "",
        headers: [
          {"x-cos-content-sha1", "b7913aa15c43be7d534b4eec6e99e8a0"},
          {"x-cos-next-append-position", "11"},
          ...
        ],
        ...
      }}
  """
  @spec append(
          host :: binary(),
          key :: binary(),
          position :: pos_integer(),
          content :: binary(),
          opts :: [headers: Tesla.Env.headers(), tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def append(host, key, position, content, opts \\ []) do
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :post,
      url: host <> "/" <> key,
      query: %{append: "", position: position},
      headers: headers,
      body: content,
      opts: opts[:tesla_opts]
    )
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
          {"server", "tencent-cos"},
          {"data", "Tue, 29 Mar 2022 16:39:58 GMT"},
          ...
        ],
        ...
      }}
  """
  @spec copy(
          host :: binary(),
          key :: binary(),
          source :: binary(),
          opts :: [headers: Tesla.Env.headers(), tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def copy(host, key, source, opts \\ []) do
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :put,
      url: host <> "/" <> key,
      headers: [{"x-cos-copy-source", source} | headers],
      opts: opts[:tesla_opts],
      result_key: "copy_object_result"
    )
  end

  @doc """
  查询对象元数据 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7745)
  """
  @spec head(
          host :: binary(),
          key :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            headers: Tesla.Env.headers(),
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def head(host, key, opts \\ []) do
    version_id = get_in(opts, [:query, :version_id])
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :head,
      url: host <> "/" <> key,
      query: %{versionId: version_id},
      headers: headers,
      opts: opts[:tesla_opts]
    )
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
  @spec exists?(
          host :: binary(),
          key :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            headers: Tesla.Env.headers(),
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: boolean()
  def exists?(host, key, opts \\ []) do
    with {:ok, _response} <- head(host, key, opts) do
      true
    else
      _ -> false
    end
  end

  @doc """
  删除单个对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7743)

  ## 示例

      COS.Object.delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt")

      # 删除“文件夹”，如果“文件夹”内有对象，则不会删除。
      COS.Object.delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example/")
  """
  @spec delete(
          host :: binary(),
          key :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def delete(host, key, opts \\ []) do
    version_id = get_in(opts, [:query, :version_id])

    HTTPClient.request(
      method: :delete,
      url: host <> "/" <> key,
      query: %{versionId: version_id},
      opts: opts[:tesla_opts]
    )
  end

  @doc """
  删除多个对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/8289)

  ## 示例

      iex> COS.Object.multi_delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", %{
             object: [%{key: "example.txt"}, %{key: "error.txt"}]
           })
      {:ok, %Tesla.Env{
        body: %{
          "deleted" => [%{
            "key" => "example.txt",
            ...
          }],
          "error" => [%{
            "key" => "error.txt",
            ...
          }]
        },
        ...
      }}

      # Quiet 模式，在响应中仅包含删除失败的对象信息和错误信息
      iex> COS.Object.multi_delete("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", %{
             object: [%{key: "example.txt"}, %{key: "error.txt"}],
             quiet: true
           })
      {:ok, %Tesla.Env{
        body: %{
          "deleted" => [],
          "error" => [%{
            "key" => "error.txt",
            ...
          }]
        },
        ...
      }}
  """
  @spec multi_delete(
          host :: binary(),
          body :: %{
            :object => [%{:key => binary(), optional(:version_id) => binary()}],
            optional(:quiet) => boolean()
          },
          opts :: [tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def multi_delete(host, body, opts \\ []) do
    body = {:delete, body}

    with {:ok, response} <-
           HTTPClient.request(
             method: :post,
             url: host <> "/?delete",
             body: body,
             opts: opts[:tesla_opts]
           ) do
      body =
        Enum.reduce(["deleted", "error"], %{}, fn key, acc ->
          value =
            response.body
            |> get_in(["delete_result", key])
            |> List.wrap()

          Map.put(acc, key, value)
        end)

      {:ok, %{response | body: body}}
    end
  end

  @doc """
  获取请求预签名 URL

  说明：
    - 建议用户使用临时密钥生成预签名，通过临时授权的方式进一步提高预签名上传、下载等请求的安全性。
      申请临时密钥时，请遵循[最小权限指引原则](https://cloud.tencent.com/document/product/436/38618)，防止泄漏目标存储桶或对象之外的资源。
    - 如果您一定要使用永久密钥来生成预签名，建议永久密钥的权限范围仅限于上传或下载操作，以规避风险。
    - 获取对象的 URL 并下载对象参数，可在获取的 URL 后拼接参数 `response-content-disposition=attachment`。

  ## 示例

      iex> COS.Object.get_presigned_url("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt")
      "https://bucket-1250000000.cos.ap-beijing.myqcloud.com/example.txt?q-ak=AKIDb************************DmNIJ&q-header-list=&q-key-time=1649011703%3B1649012603&q-sign-algorithm=sha1&q-sign-time=1649011703%3B1649012603&q-signature=a9c13b2b1e09c5ce46df0242ac37b9cb828c0d6b&q-url-param-list="
  """
  @spec get_presigned_url(
          host :: binary(),
          key :: binary(),
          opts :: [
            method: Tesla.Env.method(),
            query: Tesla.Env.query(),
            headers: Tesla.Env.headers(),
            expired_at: COS.Auth.expired_at(),
            expire_in: COS.Auth.expire_in()
          ]
        ) :: binary()
  def get_presigned_url(host, key, opts \\ []) do
    method = opts[:method] || :get
    path = "/" <> key
    query = opts[:query] || %{}

    query =
      method
      |> COS.Auth.get(path,
        query: query,
        headers: opts[:headers],
        expire_in: opts[:expire_in],
        expired_at: opts[:expired_at]
      )
      |> Map.new()
      |> Map.merge(query)
      |> URI.encode_query()

    %{URI.parse(host) | path: path, query: query}
    |> URI.to_string()
  end

  @doc """
  下载对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7753)

  ## 示例

      iex> COS.Object.put("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "content")
      {:ok, ...}

      iex> COS.Object.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "content")
      {:ok, %Tesla.Env{
        body: "content",
        headers: [
          {"content-type", "application/octet-stream"},
          {"content-length", "7"},
          ...
        ],
        ...
      }}

      # 指定 Range 请求头部下载部分内容
      iex> COS.Object.get("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "content", headers: [
             {"range", "bytes=0-2"}
           ])
      {:ok, %Tesla.Env{
        body: "con",
        headers: [
          {"content-type", "application/octet-stream"},
          {"content-length", "3"},
          {"accept-ranges", "bytes"},
          {"content-range", "bytes 0-0/3"},
          ...
        ],
        ...
      }}
  """
  @spec get(
          host :: binary(),
          key :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            headers: Tesla.Env.headers(),
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def get(host, key, opts \\ []) do
    version_id = get_in(opts, [:query, :version_id])
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :get,
      url: host <> "/" <> key,
      query: %{versionId: version_id},
      headers: headers,
      opts: opts[:tesla_opts]
    )
  end

  @doc """
  下载对象到本地文件

  ## 示例

      iex> COS.Object.get_to_file("https://bucket-1250000000.cos.ap-beijing.myqcloud.com", "example.txt", "./example.txt")
      {:ok, %Tesla.Env{
        body: "content",
        headers: [
          {"content-type", "application/octet-stream"},
          {"content-length", "7"},
          ...
        ],
        ...
      }}
  """
  @spec get_to_file(
          host :: binary(),
          key :: binary(),
          path :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            headers: Tesla.Env.headers(),
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def get_to_file(host, key, path, opts \\ []) do
    with {:ok, response} <- get(host, key, opts),
         :ok <- File.write(path, response.body) do
      {:ok, response}
    end
  end

  @doc """
  恢复归档对象 - [腾讯云文档](https://cloud.tencent.com/document/product/436/12633)
  """
  @spec restore(
          host :: binary(),
          key :: binary(),
          body :: %{days: pos_integer(), c_a_s_job_parameters: %{tier: binary()}},
          opts :: [headers: Tesla.Env.headers(), tesla_opts: Tesla.Env.opts()]
        ) :: Tesla.Env.t()
  def restore(host, key, body, opts \\ []) do
    body = {:restore_request, body}
    version_id = get_in(opts, [:query, :version_id])
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :post,
      url: host <> "/" <> key,
      query: %{restore: "", versionId: version_id},
      headers: headers,
      body: body,
      opts: opts[:tesla_opts]
    )
  end
end
