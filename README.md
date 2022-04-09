# COS

[![Build Status](https://github.com/oo6/tencent_cloud_cos/workflows/CI/badge.svg)](https://github.com/oo6/tencent_cloud_cos/actions?query=workflow%3ACI)
[![Hex.pm Version](https://img.shields.io/hexpm/v/tencent_cloud_cos.svg)](https://hex.pm/packages/tencent_cloud_cos)

腾讯云对象存储 COS(Cloud Object Storage) Elixir SDK ([XML API](https://cloud.tencent.com/document/product/436/7751))

## Installation

The package can be installed by adding `tencent_cloud_cos` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tencent_cloud_cos, "~> 0.1.0"}
  ]
end
```

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
