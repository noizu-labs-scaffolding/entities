defmodule Mix.Tasks.Nz.Gen.Entity do
  @moduledoc """
  mix nz.gen.entity Repo Entity plural_snake --identifier:uuid --field=field_name:type --sref=reference --store=ecto
  example: mix nz.gen.entity Users User users --identifier:uuid --field=name:string --field=email:string --field=password:string --store=ecto --live
  use --no-live to prevent liveview generation
  """
  use Mix.Task
  @shortdoc "Setup new Entities"
  @author Application.compile_env(Mix.Project.config()[:app], :author, "General")
  @org Application.compile_env(Mix.Project.config()[:app], :group, "General")

  def run([context_name, entity_name, table_name | params]) do
    create_entity(context_name, entity_name, table_name, params)
  end

  def create_entity(context_name, entity_name, table_name, params) do
    app_name = Mix.Project.config()[:app] |> Atom.to_string()

    repo_snake = Macro.underscore(context_name)
    entity_snake = Macro.underscore(entity_name)
    repo_filename = "lib/#{app_name}/#{repo_snake}.ex"
    entity_filename = "lib/#{app_name}/#{repo_snake}/#{entity_snake}.ex"
    with false <- File.exists?(repo_filename) && {:error, "Repo exists: #{repo_filename}"},
         false <- File.exists?(entity_filename) && {:error, "Entity exists: #{entity_filename}"},
         {:ok, {context_contents, entity_contents}} <- entity_template(context_name, entity_name, params) do
      with :ok <- File.write(repo_filename, context_contents) do
        IO.puts("#{repo_filename} Generated")
      end
      with :ok <- File.write(entity_filename, entity_contents) do
        IO.puts("#{entity_filename} Generated")
      end

      app_name = app_name()
      live = Enum.find_value(params, & &1 == "--live" && :live)
      live = Enum.find_value(params, fn
        "--live" -> :live
        "--no-live" -> :no_live
      end)

      params = prep_params(params)
      fields = extract_fields(params[:field])
      storage = extract_storage(params[:store])

      unless live == :no_live do
        add_live(context_name, entity_name, table_name, fields)
      else
        # Ecto Setup
        if storage[:ecto] do
          add_ecto(context_name, entity_name, table_name, fields)
        end
      end




    end



  end

  defp app_name() do
    Mix.Project.config()[:app]
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("")
  end

  defp entity_name(name, _) do
    String.split(name, ".")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(".")
  end

  defp prep_params(params) do
    Enum.group_by(params, fn param ->
      cond do
        String.starts_with?(param, "sref=") -> :sref
        String.starts_with?(param, "field=") -> :field
        String.starts_with?(param, "identifier=") -> :identifier
        String.starts_with?(param, "store=") -> :store
        :else -> :misc
      end
    end)
  end

  defp extract_sref(params) do
    Enum.find_value(params, fn param ->
      case String.split(param, "=") do
        ["sref", x] -> x
        _ -> nil
      end
    end)
  end

  defp extract_identifier(nil), do: nil
  defp extract_identifier(params) do
    Enum.map(
      params,
      fn
        "identifier:" <> f ->
          case f do
            "uuid" -> ":uuid"
            "integer" -> ":integer"
            "ref" -> ":ref"
            "dual_ref" -> ":dual_ref"
            _ -> f
          end
        _ ->
          nil
      end
    )
    |> Enum.filter(& &1)
    |> List.first()
  end

  defp extract_fields(nil), do: []

  defp extract_fields(params) do
    Enum.map(
      params,
      fn
        "field=" <> f ->
          case String.split(f, ":") do
            [name, type] ->
              {:field, {name, type}}
          end

        _ ->
          nil
      end
    )
    |> Enum.filter(& &1)
  end

  defp extract_storage(nil), do: []

  defp extract_storage(params) do
    Enum.map(
      params,
      fn
        "store=ecto" -> {:ecto, :storage}
        "store=redis" -> {:redis, :storage}
        "store=mnesia" -> {:mnesia, :storage}
        _ -> nil
      end
    )
    |> Enum.filter(& &1)
  end

  defp add_live(context_name, entity_name, table, fields) do
    ecto = Enum.map(fields,
             fn {_, {field, type}} ->
               try do
                 m = String.to_existing_atom(type)
                 with {:ok, x} <- apply(m, :ecto_gen_string, [field]) do
                   x
                 else
                   _ -> nil
                 end
               rescue
                 _ -> "#{field}:#{type}"
               end
             end) |> Enum.reject(&is_nil/1) |> List.flatten()
    ecto = ["Schema" <> "." <> context_name, entity_name, table | ecto]
    apply(Mix.Tasks.Phx.Gen.Live, :run, [ecto])
  end

  defp add_ecto(context_name, entity_name, table, fields) do
    ecto = Enum.map(fields,
             fn {_, {field, type}} ->
               try do
                 m = String.to_existing_atom(type)
                 with {:ok, x} <- apply(m, :ecto_gen_string, [field]) do
                   x
                 else
                   _ -> nil
                 end
               rescue
                 _ -> "#{field}:#{type}"
               end
             end) |> Enum.reject(&is_nil/1) |> List.flatten()
    ecto = ["Schema" <> "." <> context_name <> "." <> entity_name, table | ecto]
    apply(Mix.Tasks.Phx.Gen.Schema, :run, [ecto])
  end

  def entity_template(context_name, entity_name, params) do
    app_name = app_name()
    sm = app_name <> "." <> context_name <> "." <> entity_name
    repo_module = app_name <> "." <> context_name
    params = prep_params(params)
    # Sref, Fields, Storage
    sref = extract_sref(params[:sref])
    fields = extract_fields(params[:field])
    identifier_type = extract_identifier(params[:identifier]) || ":uuid"
    storage = extract_storage(params[:store])

    # Ecto Setup
    # storage[:ecto] && add_ecto(name, fields)

    # Payload Snippet
    entity_fields =
      Enum.map(fields, fn {_, {field, type}} ->
        unless String.downcase(type) == type do
          "field :#{field}, nil, #{type}"
        else
          "field :#{field}"
        end
      end)
      |> Enum.join("\n    ")

    entity_persistence =
      Enum.map(
        storage,
        fn {store, settings} ->
          "@persistence {#{inspect(store)}, #{inspect(settings)}}"
        end
      )
      |> Enum.join("\n   ")

    entity = """
      #-------------------------------------------------------------------------------
      # Author: #{@author}
      # Copyright (C) #{DateTime.utc_now().year} #{@org} All rights reserved.
      #-------------------------------------------------------------------------------

      defmodule #{sm} do
        use Noizu.Entities

        @vsn 1.0
        #{(sref && "@sref \"#{sref}\"") || ""}
        #{entity_persistence}
        def_entity do
          identifier #{identifier_type}
          #{entity_fields}
        end
      end
    """

    singular = Inflex.singularize(entity_name)
    plural = Inflex.pluralize(entity_name)
    singular_snake = Macro.underscore(singular)
    plural_snake = Macro.underscore(plural)

    repo = """
      #-------------------------------------------------------------------------------
      # Author: #{@author}
      # Copyright (C) #{DateTime.utc_now().year} #{@org} All rights reserved.
      #-------------------------------------------------------------------------------

      defmodule #{repo_module} do
        alias #{app_name}.#{context_name}.#{entity_name}
        use Noizu.Repo
        def_repo()

        @doc \"""
        Returns the list of #{plural_snake}.
        \"""
        def list_#{plural_snake}(context) do
          list(context)
        end

        @doc \"""
        Gets a single #{singular_snake}.

        \"""
        def get_#{singular_snake}(id, context), do: get(id, context)

        @doc \"""
        Creates a #{singular_snake}.
        \"""
        def create_#{singular_snake}(#{singular_snake}, context) do
          create(#{singular_snake}, context)
        end

        @doc \"""
        Updates a #{singular_snake}.
        \"""
        def update_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, attrs, context) do
          #{singular_snake}
          |> change_#{singular_snake}(attrs)
          |> update(context)
        end

        @doc \"""
        Deletes a #{singular_snake}.
        \"""
        def delete_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, context) do
          delete(#{singular_snake}, context)
        end

        @doc \"""
        Returns an Changeset for tracking #{singular_snake} changes.
        \"""
        def change_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, attrs \\ %{}) do
          # NYI: Implement custom changeset logic here.
          #{singular_snake}
        end
      end
    """
    {:ok, {repo, entity}}
  end
end
