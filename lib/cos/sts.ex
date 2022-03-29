defmodule COS.STS do
  @moduledoc """
  临时密钥生成及使用指引 - [腾讯云文档](https://cloud.tencent.com/document/product/436/14048)
  """

  @doc """
  获取联合身份临时访问凭证 - [腾讯云文档](https://cloud.tencent.com/document/api/1312/48195)

  ## 示例

      iex> COS.STS.get_credential(
             "cos-sts-elixir",
             %{
               version: "2.0",
               statement: [
                 %{
                   effect: "allow",
                   action: ["cos:PostObject"],
                   resource: ["qcs::cos:ap-beijing:uid/1250000000:bucket-1250000000/*"]
                 }
               ]
             },
             "ap-beijing"
           )
      {:ok, %Tesla.Env{
        body: %{
          "credentials" => %{
            "token" => "xxx",
            ...
          }
        },
        ...
      }}

      iex> COS.STS.get_credential(
             "cos-sts-elixir",
             %{
               version: "2.0",
               statement: [
                 %{
                   effect: "allow",
                   action: ["cos:PostObject"],
                   resource: ["invalid resouce"]
                 }
               ]
             },
             "ap-beijing"
           )
      {:error, %Tesla.Env{
        body: %{
          "error" => %{
            "code" => "InvalidParameter.ResouceError",
            "message" => "resource error"
          }
          "request_id" => "6734caac-d3bf-4465-adf3-2e300e5063ce"
        },
        ...
      }}
  """
  @spec get_credential(
          name :: binary(),
          policy :: map(),
          region :: binary(),
          opts :: Tesla.Env.opts()
        ) :: Tesla.Env.t()
  def get_credential(name, policy, region, opts \\ []) do
    host = "sts.#{region}.tencentcloudapi.com"

    headers = [
      {"host", host},
      {"content-type", "application/json"},
      {"x-tc-timestamp", DateTime.utc_now() |> DateTime.to_unix()}
    ]

    body =
      %{
        Name: name,
        Policy: policy |> Jason.encode!() |> URI.encode_www_form()
      }
      |> Jason.encode!()

    config = COS.config()
    authorization = get_authorization(body, headers, config)

    headers =
      headers ++
        [
          {"x-tc-Action", "GetFederationToken"},
          {"x-tc-region", region},
          {"x-tc-version", "2018-08-13"},
          {"authorization", authorization}
        ]

    options = [method: :post, url: "https://" <> host, body: body, headers: headers, opts: opts]

    config.http_client[:middleware]
    |> Tesla.client(config.http_client[:adapter])
    |> Tesla.request(options)
    |> case do
      {:ok, response} ->
        response.body
        |> Jason.decode!()
        |> COS.Utils.underscore_keys()
        |> Map.get("response")
        |> case do
          %{"credentials" => _} = body -> {:ok, %{response | body: body}}
          body -> {:error, %{response | body: body}}
        end

      error ->
        error
    end
  end

  defp get_authorization(body, headers, config) do
    # https://cloud.tencent.com/document/api/1312/48202
    # 1. 拼接规范请求串
    sorted_headers =
      headers
      |> Enum.map(fn {key, value} -> {String.downcase(key), value} end)
      |> Enum.sort_by(&elem(&1, 0))

    canonical_headers =
      sorted_headers
      |> Enum.map(fn {key, value} -> "#{key}:#{value}\n" end)
      |> Enum.join()

    signed_headers = sorted_headers |> Enum.map(&elem(&1, 0)) |> Enum.join(";")

    hashed_request_payload =
      :sha256
      |> :crypto.hash(body)
      |> Base.encode16(case: :lower)

    canonical_request =
      [
        "POST",
        "/",
        "",
        canonical_headers,
        signed_headers,
        hashed_request_payload
      ]
      |> Enum.join("\n")

    # 2. 拼接待签名字符串
    algorithm = "TC3-HMAC-SHA256"

    request_timestamp =
      Enum.find_value(sorted_headers, fn {key, value} ->
        if key == "x-tc-timestamp", do: value
      end)

    date = request_timestamp |> DateTime.from_unix!() |> DateTime.to_date() |> Date.to_string()
    credential_scope = "#{date}/sts/tc3_request"

    hashed_canonical_request =
      :sha256
      |> :crypto.hash(canonical_request)
      |> Base.encode16(case: :lower)

    string_to_sign =
      "#{algorithm}\n#{request_timestamp}\n#{credential_scope}\n#{hashed_canonical_request}"

    # 3. 计算签名
    signature =
      ("TC3" <> config.secret_key)
      |> hmac_sha256(date)
      |> hmac_sha256("sts")
      |> hmac_sha256("tc3_request")
      |> hmac_sha256(string_to_sign)
      |> Base.encode16(case: :lower)

    # 4. 拼接 Authorization
    algorithm <>
      " " <>
      Enum.join(
        [
          "Credential=#{config.secret_id}/#{credential_scope}",
          "SignedHeaders=#{signed_headers}",
          "Signature=#{signature}"
        ],
        ", "
      )
  end

  defp hmac_sha256(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
end
