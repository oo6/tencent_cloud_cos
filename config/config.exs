import Config

if "#{Mix.env()}.exs" |> Path.expand(__DIR__) |> File.exists?() do
  import_config "#{Mix.env()}.exs"
end
