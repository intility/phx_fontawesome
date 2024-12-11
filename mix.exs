defmodule PhxFontawesome.MixProject do
  use Mix.Project

  @version "1.2.3"
  @source_url "https://github.com/Intility/phx_fontawesome"

  def project do
    [
      app: :phx_fontawesome,
      description:
        "A simple Mix task that generates Phoenix Components from Font Awesome SVG files.",
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        name: "phx_fontawesome",
        files:
          ~w(lib/mix/tasks/phx_fontawesome/generate.ex lib/phx_fontawesome.ex .formatter.exs mix.exs README.md LICENSE),
        licenses: ["MIT"],
        maintainers: ["Rolf Håvard Blindheim <rolf.havard.blindheim@intility.no>"],
        links: %{"GitHub" => @source_url}
      ],
      docs: [
        main: "readme",
        logo: "assets/logo.png",
        name: "PhxFontawesome",
        source_ref: "v#{@version}",
        source_url: @source_url,
        extras: [
          "README.md"
        ]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "deps/phx_fontawesome/lib"]
  defp elixirc_paths(_), do: ["lib", "deps/phx_fontawesome/lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.35", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4", only: [:dev, :test]},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phx_component_helpers, "~> 1.4"}
    ]
  end
end
