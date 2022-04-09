defmodule COS.MixProject do
  use Mix.Project

  @source_url "https://github.com/oo6/tencent_cloud_cos"
  @version "0.1.0"

  def project do
    [
      app: :tencent_cloud_cos,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "腾讯云对象存储 COS(Cloud Object Storage) Elixir SDK",
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

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

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "LICENSE", "CHANGELOG.md"]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Milo Lee"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/tencent_cloud_cos/changelog.html"
      }
    ]
  end
end
