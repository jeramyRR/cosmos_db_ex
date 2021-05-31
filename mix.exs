defmodule CosmosDbEx.MixProject do
  use Mix.Project

  @source_link "https://github.com/jeramyRR/cosmos_db_ex"

  def project do
    [
      app: :cosmos_db_ex,
      version: "0.1.1",
      elixir: "~> 1.11",
      description: description(),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      source_url: @source_link
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CosmosDbEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.7"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.7"},
      # Develop Dependencies
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts",
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp description do
    "Azure Cosmos Db driver using the SQL REST API."
  end

  defp package do
    [
      maintainers: ["Jeramy Singleton"],
      files: ~w(lib .formatter.exs mix.exs README.md),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_link}
    ]
  end
end
