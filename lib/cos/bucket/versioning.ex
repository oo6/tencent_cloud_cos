defmodule COS.Bucket.Versioning do
  @moduledoc """
  版本控制用于实现在相同存储桶中存放同一对象的多个版本。例如，在一个存储桶中，您可以存放多个对象键同为 picture.jpg 的对象，但其版本 ID 不同，例如100000、100101和120002等。

  [腾讯云文档](https://cloud.tencent.com/document/product/436/19883)
  """

  alias COS.HTTPClient

  @doc """
  查询版本控制 - [腾讯云文档](https://cloud.tencent.com/document/product/436/19888)
  """
  @spec get(host :: binary(), opts :: [testla_opts: Tesla.Env.opts()]) :: Tesla.Env.t()
  def get(host, opts \\ []) do
    case HTTPClient.request(
           method: :get,
           url: host <> "/?versioning",
           opts: opts[:tesla_opts],
           result_key: "versioning_configuration"
         ) do
      {:ok, %{body: nil} = response} -> {:ok, %{response | body: %{"status" => nil}}}
      other -> other
    end
  end

  @doc """
  设置版本控制 - [腾讯云文档](https://cloud.tencent.com/document/product/436/19889)
  """
  @spec put(host :: binary(), opts :: [testla_opts: Tesla.Env.opts()]) :: Tesla.Env.t()
  def put(host, body, opts \\ []) do
    body = {:versioning_configuration, body}

    HTTPClient.request(
      method: :put,
      url: host <> "/?versioning",
      body: body,
      opts: opts[:tesla_opts],
      result_key: "versioning_configuration"
    )
  end
end
