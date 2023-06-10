defmodule Noizu.Entities.MixProject do
  use Mix.Project

  def project do
    [
      app: :noizu_labs_entities,
      name: "NoizuLabs Entities",
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env),

    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_),     do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      #applications: [:noizu_labs_entities],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1.0", optional: true},

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]|> then(fn(deps) ->
      if Application.get_env(:noizu_labs_ecto_entities, :umbrella) do
        deps ++ [{:noizu_labs_core, in_umbrella: true }]
      else
        deps ++ [{:noizu_labs_core, "~> 0.1"}]
      end
    end)
  end
end
