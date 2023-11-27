defmodule Noizu.Entities.MixProject do
  use Mix.Project

  def project do
    [
      app: :noizu_labs_entities,
      name: "NoizuLabs Entities",
      version: "0.1.3",
      elixir: "~> 1.14",
      package: package(),
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp description() do
    "Elixir Entities (Structs with MetaData and Noizu EntityReference Protocol support from noizu-labs-scaffolding/core built in."
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{
        project: "https://github.com/noizu-labs-scaffolding/entities",
        noizu_labs: "https://github.com/noizu-labs",
        noizu_labs_ml: "https://github.com/noizu-labs-ml",
        noizu_labs_scaffolding: "https://github.com/noizu-labs-scaffolding",
        developer: "https://github.com/noizu"
      }
    ]
  end

  def elixirc_paths(:test), do: ["lib", "test/support"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # applications: [:noizu_labs_entities],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, github: "noizu-labs-scaffolding/jason", branch: "user_options", override: true},
      {:mimic, "~> 1.0.0", only: :test},
      {:ecto_sql, "~> 3.6"},
      {:amnesia, git: "https://github.com/noizu/amnesia.git", tag: "0.2.8", optional: true},
      {:shortuuid, "~> 3.0"},
      {:elixir_uuid, "~> 1.2", optional: true},
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
    |> then(fn deps ->
      if Application.get_env(:noizu_labs_entities, :umbrella) do
        deps ++ [{:noizu_labs_core, in_umbrella: true}]
      else
        deps ++ [{:noizu_labs_core, "~> 0.1"}]
      end
    end)
  end
end
