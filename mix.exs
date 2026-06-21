defmodule Scout.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/Scout-AI-Labs/scout-elixir"

  def project do
    [
      app: :scout_sdk,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Official Elixir SDK for the Scout web-intelligence API",
      package: package(),
      name: "Scout",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:bypass, "~> 2.1", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Scout AI Labs"],
      links: %{
        "GitHub" => @source_url,
        "Homepage" => "https://usescout.sh"
      }
    ]
  end

  defp docs do
    [
      main: "Scout",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
