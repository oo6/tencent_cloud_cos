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
          {"server", "tencent-cos"},
          {"data", "Tue, 29 Mar 2022 16:39:58 GMT"},
          ...
        ],
        ...
      }}

      # 创建多 AZ 存储桶
      COS.Bucket.put(
        "https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
        body: %{bucket_a_z_config: "MAZ"}
      )
  """
  @spec put(
          host :: binary(),
          opts :: [
            body: %{bucket_a_z_config: binary()} | nil,
            headers: Tesla.Env.headers(),
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def put(host, opts \\ []) do
    body = if opts[:body], do: {:create_bucket_configuration, opts[:body]}
    headers = opts[:headers] || []

    HTTPClient.request(
      method: :put,
      url: host,
      body: body,
      headers: headers,
      opts: opts[:tesla_opts]
    )
  end

  @doc """
  删除存储桶 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7732)
  """
  @spec delete(host :: binary(), opts :: [tesla_opts: Tesla.Env.opts()]) :: Tesla.Env.t()
  def delete(host, opts \\ []) do
    HTTPClient.request(method: :delete, url: host, opts: opts[:tesla_opts])
  end

  @doc """
  检索存储桶 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7735)

  确认该存储桶是否存在，是否有权限访问。有以下几种情况：
    - 存储桶存在且有读取权限，返回 HTTP 状态码为200。
    - 无存储桶读取权限，返回 HTTP 状态码为403。
    - 存储桶不存在，返回 HTTP 状态码为404。
  """
  @spec head(host :: binary(), opts :: [tesla_opts: Tesla.Env.opts()]) :: Tesla.Env.t()
  def head(host, opts \\ []) do
    HTTPClient.request(method: :head, url: host, opts: opts[:tesla_opts])
  end

  @doc """
  查询对象列表 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7734)
  """
  @spec list_objects(
          host :: binary(),
          opts :: [
            query: %{
              optional(:prefix) => binary(),
              optional(:delimiter) => binary(),
              optional(:marker) => binary(),
              optional(:encoding_type) => binary(),
              optional(:max_keys) => pos_integer()
            },
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def list_objects(host, opts \\ []) do
    query =
      case opts[:query] do
        nil ->
          %{}

        query ->
          {query, other_query} = Map.split(query, [:prefix, :delimiter, :marker])

          query
          |> Map.merge(%{
            "encoding-type": other_query[:encoding_type],
            "max-keys": other_query[:max_keys]
          })
          |> Enum.filter(&elem(&1, 1))
          |> Map.new()
      end

    with {:ok, response} <-
           HTTPClient.request(
             method: :get,
             url: host <> "/",
             query: query,
             result_key: "list_bucket_result",
             opts: opts[:tesla_opts]
           ) do
      body =
        response.body
        |> Map.update("contents", [], fn contents ->
          contents
          |> List.wrap()
          |> Enum.map(fn content -> Map.update!(content, "size", &String.to_integer/1) end)
        end)
        |> Map.update!("is_truncated", &String.to_atom/1)
        |> Map.update!("max_keys", &String.to_integer/1)

      {:ok, %{response | body: body}}
    end
  end

  @doc """
  查询对象历史版本列表 - [腾讯云文档](https://cloud.tencent.com/document/product/436/35521)
  """
  @spec list_objects_with_versions(
          host :: binary(),
          opts :: [
            query: %{
              optional(:prefix) => binary(),
              optional(:delimiter) => binary(),
              optional(:encoding_type) => binary(),
              optional(:max_keys) => pos_integer(),
              optional(:key_maker) => binary(),
              optional(:version_id_marker) => binary()
            },
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def list_objects_with_versions(host, opts \\ []) do
    query =
      case opts[:query] do
        nil ->
          %{}

        query ->
          {query, other_query} = Map.split(query, [:prefix, :delimiter])

          query
          |> Map.merge(%{
            "encoding-type": other_query[:encoding_type],
            "max-keys": other_query[:max_keys],
            "key-marker": other_query[:key_maker],
            "version-id-marker": other_query[:version_id_marker]
          })
          |> Enum.filter(&elem(&1, 1))
          |> Map.new()
      end

    with {:ok, response} <-
           HTTPClient.request(
             method: :get,
             url: host <> "/?versions",
             query: query,
             result_key: "list_versions_result",
             opts: opts[:tesla_opts]
           ) do
      body =
        response.body
        |> Map.update("version", [], fn versions ->
          versions
          |> List.wrap()
          |> Enum.map(fn version ->
            version
            |> Map.update!("size", &String.to_integer/1)
            |> Map.update!("is_latest", &String.to_atom/1)
            |> Map.update!("version_id", fn
              "null" -> nil
              version_id -> version_id
            end)
          end)
        end)
        |> Map.update!("is_truncated", &String.to_atom/1)
        |> Map.update!("max_keys", &String.to_integer/1)

      {:ok, %{response | body: body}}
    end
  end
end
