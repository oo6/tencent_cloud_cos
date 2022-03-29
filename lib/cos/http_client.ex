defmodule COS.HTTPClient do
  # @moduledoc false

  @doc """
  See `Tesla.request/1`
  """
  @spec request(options :: [Tesla.option()]) :: Tesla.Env.t()
  def request(options) do
    method = options[:method]
    headers = options[:headers] || []
    body = map_to_xml(options[:body])

    headers =
      if method in [:post, :put] && Enum.all?(headers, &(elem(&1, 0) != "transfer-encoding")) do
        [{"content-length", byte_size(body)} | headers]
      else
        headers
      end

    headers =
      if method in [:post, :put] && body != "" do
        [{"content-md5", :crypto.hash(:md5, body) |> Base.encode64()} | headers]
      else
        headers
      end

    path = URI.parse(options[:url]).path || "/"
    config = COS.config()
    authorization = get_authorization(method, path, options[:query] || [], headers, config)

    options =
      options
      |> Keyword.put(:headers, [{"authorization", authorization} | headers])
      |> Keyword.put(:body, body)

    config.http_client[:middleware]
    |> Tesla.client(config.http_client[:adapter])
    |> Tesla.request(options)
    |> case do
      {:ok, %{status: status, body: ""} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, %{status: status} = response} when status in 200..299 ->
        body = xml_to_map(response.body)
        result_key = get_in(options, [:opts, :result_key])

        response = %{response | body: if(result_key, do: body[result_key], else: body)}

        {:ok, response}

      {:ok, %{body: ""} = response} ->
        {:error, response}

      {:ok, response} ->
        {:error, %{response | body: xml_to_map(response.body)["error"]}}

      error ->
        error
    end
  end

  defp get_authorization(method, path, query, headers, config) do
    # https://cloud.tencent.com/document/product/436/7778
    # 1. 生成 KeyTime
    start_timestamp = DateTime.utc_now() |> DateTime.to_unix()
    key_time = "#{start_timestamp};#{start_timestamp + 900}"

    # 2. 生成 SignKey
    sign_key =
      :hmac
      |> :crypto.mac(:sha, config.secret_key, key_time)
      |> Base.encode16(case: :lower)

    # 3. 生成 UrlParamList 和 HttpParameters
    sorted_query =
      query
      |> Enum.map(fn {key, value} -> {url_encode(key) |> String.downcase(), url_encode(value)} end)
      |> Enum.sort_by(&elem(&1, 0))

    url_param_list = sorted_query |> Enum.map(&elem(&1, 0)) |> Enum.join(";")

    http_parameters =
      sorted_query
      |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
      |> Enum.join("&")

    # 4. 生成 HeaderList 和 HttpHeaders
    sorted_headers =
      headers
      |> Enum.map(fn {key, value} -> {url_encode(key) |> String.downcase(), url_encode(value)} end)
      |> Enum.sort_by(&elem(&1, 0))

    header_list = sorted_headers |> Enum.map(&elem(&1, 0)) |> Enum.join(";")

    http_headers =
      sorted_headers
      |> Enum.map(&"#{elem(&1, 0)}=#{elem(&1, 1)}")
      |> Enum.join("&")

    # 5. 生成 HttpString
    http_string = "#{method}\n#{path}\n#{http_parameters}\n#{http_headers}\n"

    # 6. 生成 StringToSign
    hashed_http_string = :sha |> :crypto.hash(http_string) |> Base.encode16(case: :lower)
    string_to_sign = "sha1\n#{key_time}\n#{hashed_http_string}\n"

    # 7. 生成 Signature
    signature =
      :hmac
      |> :crypto.mac(:sha, sign_key, string_to_sign)
      |> Base.encode16(case: :lower)

    # 8. 生成签名
    [
      "q-sign-algorithm=sha1",
      "q-ak=#{config.secret_id}",
      "q-sign-time=#{key_time}",
      "q-key-time=#{key_time}",
      "q-header-list=#{header_list}",
      "q-url-param-list=#{url_param_list}",
      "q-signature=#{signature}"
    ]
    |> Enum.join("&")
  end

  defp url_encode(value) do
    value
    |> to_string()
    |> URI.encode_www_form()
    |> String.replace("+", "%20")
  end

  defp xml_to_map(xml), do: xml |> XmlToMap.naive_map() |> COS.Utils.underscore_keys()

  defp map_to_xml(nil), do: ""
  defp map_to_xml(string) when is_binary(string), do: string

  defp map_to_xml({key, map}) when is_map(map) do
    {camelize_key(key), nil, Enum.map(map, &map_to_xml/1)}
    |> XmlBuilder.generate(format: :none)
  end

  defp map_to_xml({key, other}), do: {camelize_key(key), nil, other}

  defp camelize_key(key), do: key |> to_string() |> Macro.camelize()
end
