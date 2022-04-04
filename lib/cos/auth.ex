defmodule COS.Auth do
  @moduledoc false

  @type expired_at :: DateTime.t()
  @type expire_in :: pos_integer() | {pos_integer(), :second | :minute | :hour | :day}

  @doc """
  请求签名 - [腾讯云文档](https://cloud.tencent.com/document/product/436/7778)
  """
  @spec get(
          method :: Tesla.Env.method(),
          path :: binary(),
          opts :: [
            query: Tesla.Env.query(),
            headers: Tesla.Env.headers(),
            expired_at: expired_at(),
            expire_in: expire_in()
          ]
        ) :: keyword()
  def get(method, path, opts \\ []) do
    query = opts[:query] || %{}
    headers = opts[:headers] || []
    config = COS.config()

    # 1. 生成 KeyTime
    start_timestamp = DateTime.utc_now() |> DateTime.to_unix()
    end_timestamp = end_timestamp(start_timestamp, opts)
    key_time = "#{start_timestamp};#{end_timestamp}"

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

    [
      {"q-sign-algorithm", "sha1"},
      {"q-ak", config.secret_id},
      {"q-sign-time", key_time},
      {"q-key-time", key_time},
      {"q-header-list", header_list},
      {"q-url-param-list", url_param_list},
      {"q-signature", signature}
    ]
  end

  @doc false
  def end_timestamp(start_timestamp, opts \\ []) do
    case {opts[:expired_at], opts[:expire_in]} do
      {nil, nil} -> start_timestamp + 900
      {%DateTime{} = expired_at, _} -> DateTime.to_unix(expired_at)
      {_, expire_in} -> start_timestamp + duration(expire_in)
    end
  end

  defp url_encode(value) do
    value
    |> to_string()
    |> URI.encode_www_form()
    |> String.replace("+", "%20")
  end

  defp duration(seconds) when is_integer(seconds), do: seconds
  defp duration({seconds, :second}), do: duration(seconds)
  defp duration({minutes, :minute}), do: duration(minutes * 60)
  defp duration({hours, :hour}), do: duration(hours * 60 * 60)
  defp duration({days, :day}), do: duration(days * 24 * 60 * 60)
end
