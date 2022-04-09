defmodule COS.Utils do
  @type expire_in :: pos_integer() | {pos_integer(), :second | :minute | :hour | :day}

  @doc """
  将驼峰 key 转换为下划线风格
  """
  @spec underscore_keys(value :: any()) :: any()
  def underscore_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {Macro.underscore(key), underscore_keys(value)} end)
  end

  def underscore_keys(list) when is_list(list) do
    Enum.map(list, &underscore_keys/1)
  end

  def underscore_keys(other), do: other

  @doc """
  根据 {amount, unit} 格式计算出多少秒
  """
  @spec to_seconds(expire_in :: expire_in()) :: pos_integer()
  def to_seconds(seconds) when is_integer(seconds), do: seconds
  def to_seconds({seconds, :second}), do: to_seconds(seconds)
  def to_seconds({minutes, :minute}), do: to_seconds(minutes * 60)
  def to_seconds({hours, :hour}), do: to_seconds(hours * 60 * 60)
  def to_seconds({days, :day}), do: to_seconds(days * 24 * 60 * 60)

  # TODO: remove when we require OTP 22.1
  if Code.ensure_loaded?(:crypto) and function_exported?(:crypto, :mac, 4) do
    def hmac(sub_type, key, data), do: :crypto.mac(:hmac, sub_type, key, data)
  else
    def hmac(sub_type, key, data), do: :crypto.hmac(sub_type, key, data)
  end
end
