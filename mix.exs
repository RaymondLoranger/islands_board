defmodule Islands.Board.MixProject do
  use Mix.Project

  def project do
    [
      app: :islands_board,
      version: "0.1.12",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      name: "Islands Board",
      source_url: source_url(),
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp source_url do
    "https://github.com/RaymondLoranger/islands_board"
  end

  defp description do
    """
    Models a board in the Game of Islands.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Raymond Loranger"],
      licenses: ["MIT"],
      links: %{"GitHub" => source_url()}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_tasks,
       github: "RaymondLoranger/mix_tasks", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:islands_config, "~> 0.1", runtime: false},
      {:islands_coord, "~> 0.1"},
      {:islands_island, "~> 0.1"},
      {:poison, "~> 3.1"},
      {:jason, "~> 1.0"}
    ]
  end
end
