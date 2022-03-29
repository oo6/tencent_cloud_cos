defmodule COS do
  @moduledoc """
  腾讯云对象存储 COS(Cloud Object Storage) - [腾讯云文档](https://cloud.tencent.com/document/product/436/7751)
  """

  @default_http_client [adapter: Tesla.Adapter.Hackney, middleware: []]

  @doc """
  获取配置数据

  ## 示例

  在你的 config.exs 中配置：

      config :tencent_cloud_cos,
        secret_id: "AKIDb************************DmNIJ",
        secret_key: "iV1oL**********************4JuFu",
        http_client: [
          adapter: Tesla.Adapter.Hackney
        ]

  如果需要，您可以获取配置：

      COS.config()[:http_client]
  """
  @spec config() :: map()
  def config do
    :tencent_cloud_cos
    |> Application.get_all_env()
    |> Map.new()
    |> merge_http_client()
  end

  defp merge_http_client(config) do
    {http_client, config} = Map.pop(config, :http_client)

    Map.merge(
      %{http_client: Keyword.merge(@default_http_client, http_client || [])},
      config
    )
  end
end
