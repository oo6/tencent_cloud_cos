defmodule COS.MixProject do
  use Mix.Project

  def project do
    [
      app: :tencent_cloud_cos,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "腾讯云对象存储 COS(Cloud Object Storage) Elixir SDK",
      docs: [
        main: "readme",
        source_url: "https://github.com/oo6/tencent_cloud_cos",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:elixir_xml_to_map, "~> 3.0"},
      {:xml_builder, "~> 2.1"},
      {:jason, "~> 1.3"},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end
end
