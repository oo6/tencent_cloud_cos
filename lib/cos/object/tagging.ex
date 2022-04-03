defmodule COS.Object.Tagging do
  @moduledoc """
  对象标签功能的实现是通过为对象添加一个键值对形式的标识，协助用户分组管理存储桶中的对象。

  [腾讯云文档](https://cloud.tencent.com/document/product/436/42993)
  """

  alias COS.HTTPClient

  @type tag :: %{key: binary(), value: binary()}

  @doc """
  设置对象标签 - [腾讯云文档](https://cloud.tencent.com/document/product/436/42997)
  """
  @spec put(
          host :: binary(),
          key :: binary(),
          body :: %{tag_set: [tag()]},
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def put(host, key, %{tag_set: tag_set}, opts \\ []) do
    version_id = get_in(opts, [:query, :version_id])
    body = {:tagging, %{tag_set: %{tag: tag_set}}}

    HTTPClient.request(
      method: :put,
      url: host <> "/" <> key,
      query: %{tagging: "", versionId: version_id},
      body: body,
      opts: opts[:tesla_opts]
    )
  end

  @doc """
  查询对象标签 - [腾讯云文档](https://cloud.tencent.com/document/product/436/42998)
  """
  @spec get(
          host :: binary(),
          key :: binary(),
          opts :: [
            query: %{optional(:version_id) => binary()} | nil,
            tesla_opts: Tesla.Env.opts()
          ]
        ) :: Tesla.Env.t()
  def get(host, key, opts \\ []) do
    version_id = get_in(opts, [:query, :version_id])

    with {:ok, response} <-
           HTTPClient.request(
             method: :get,
             url: host <> "/" <> key,
             query: %{tagging: "", versionId: version_id},
             opts: opts[:tesla_opts]
           ) do
      tag_set =
        response.body
        |> get_in(["tagging", "tag_set", "tag"])
        |> List.wrap()

      body = %{"tag_set" => tag_set}
      {:ok, %{response | body: body}}
    end
  end

  @doc """
  删除对象标签 - [腾讯云文档](https://cloud.tencent.com/document/product/436/42999)
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
      query: %{tagging: "", versionId: version_id},
      opts: opts[:tesla_opts]
    )
  end
end
