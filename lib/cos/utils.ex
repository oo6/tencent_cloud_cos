defmodule COS.Utils do
  @moduledoc false

  @doc """
  将驼峰 key 转换为下划线风格
  """
  @spec underscore_keys(value :: any()) :: any()
  def underscore_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {Macro.underscore(key), underscore_keys(value)} end)
  end

  def underscore_keys(other), do: other
end
