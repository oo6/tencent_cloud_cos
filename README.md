# COS

腾讯云对象存储 COS(Cloud Object Storage) Elixir SDK ([XML API](https://cloud.tencent.com/document/product/436/7751))

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tencent_cloud_cos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tencent_cloud_cos, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/tencent_cloud_cos>.

## Usage

First, set config:

```elixir
config :tencent_cloud_cos,
  secret_id: "AKIDb************************DmNIJ",
  secret_key: "iV1oL**********************4JuFu"
```

After that, you can upload a file:

```elixir
iex> COS.Object.put_from_file("https://bucket-1250000000.cos.ap-beijing.myqcloud.com",
 "example.txt", "./example.txt")
```
