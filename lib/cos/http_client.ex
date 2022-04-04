defmodule COS.HTTPClient do
  @moduledoc false

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

    authorization =
      method
      |> COS.Auth.get(path, query: options[:query], headers: headers)
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join("&")

    options =
      options
      |> Keyword.put(:headers, [{"authorization", authorization} | headers])
      |> Keyword.put(:body, body)

    config = COS.config()

    config.http_client[:middleware]
    |> Tesla.client(config.http_client[:adapter])
    |> Tesla.request(options)
    |> case do
      {:ok, %{status: status, headers: headers} = response} when status in 200..299 ->
        response =
          if Enum.find(headers, fn {key, value} ->
               key == "content-type" && value == "application/xml"
             end) do
            body = xml_to_map(response.body)
            result_key = options[:result_key]
            %{response | body: if(result_key, do: body[result_key], else: body)}
          else
            response
          end

        {:ok, response}

      {:ok, %{body: ""} = response} ->
        {:error, response}

      {:ok, response} ->
        {:error, %{response | body: xml_to_map(response.body)["error"]}}

      error ->
        error
    end
  end

  defp xml_to_map(xml), do: xml |> XmlToMap.naive_map() |> COS.Utils.underscore_keys()

  @doc false
  def map_to_xml(nil), do: ""

  def map_to_xml({key, map}) when is_map(map) do
    {camelize_key(key), nil, map_to_xml(map)}
    |> XmlBuilder.generate(format: :none)
  end

  def map_to_xml({key, list}) when is_list(list) do
    Enum.map(list, &{camelize_key(key), nil, map_to_xml(&1)})
  end

  def map_to_xml({key, other}), do: {camelize_key(key), nil, map_to_xml(other)}

  def map_to_xml(map_or_list) when is_map(map_or_list) or is_list(map_or_list) do
    Enum.map(map_or_list, &map_to_xml/1)
  end

  def map_to_xml(other), do: other

  defp camelize_key(key), do: key |> to_string() |> Macro.camelize()
end
