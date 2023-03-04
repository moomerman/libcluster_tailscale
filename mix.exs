defmodule LibclusterTailscale.MixProject do
  use Mix.Project

  @source_url "https://github.com/moomerman/libcluster_tailscale"
  @version "0.1.1"

  def project do
    [
      app: :libcluster_tailscale,
      version: @version,
      elixir: "~> 1.14",
      description:
        "A Cluster strategy for discovering and connecting Elixir nodes over Tailscale",
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp package() do
    [
      files: ~w(lib mix.exs README* LICENSE*),
      links: %{GitHub: @source_url},
      licenses: ["MIT"]
    ]
  end

  defp docs() do
    [
      extras: [
        "README.md": [title: "Overview"],
        LICENSE: [title: "License"]
      ],
      main: "readme"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:libcluster, "~> 3.3"},
      {:jason, "~> 1.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
