defmodule COS.Service do
  alias COS.HTTPClient

  @doc """
  查询存储桶列表 - [腾讯云文档](https://cloud.tencent.com/document/product/436/8291)

  查询请求者名下的所有存储桶列表或特定地域下的存储桶列表。
  """
  @spec list_buckets(host :: binary(), opts :: [tesla_opts: Tesla.Env.opts()]) :: Tesla.Env.t()
  def list_buckets(host, opts \\ []) do
    with {:ok, response} <- HTTPClient.request(method: :get, url: host, opts: opts[:tesla_opts]) do
      buckets =
        response.body
        |> get_in(["list_all_my_buckets_result", "buckets", "bucket"])
        |> List.wrap()

      owner = get_in(response.body, ["list_all_my_buckets_result", "owner"])

      {:ok, %{response | body: %{"buckets" => buckets, "owner" => owner}}}
    end
  end
end
