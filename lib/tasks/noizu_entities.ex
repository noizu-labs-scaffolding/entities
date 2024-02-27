defmodule Mix.Tasks.Nz.Gen.Entity do
  @moduledoc """
  mix nz.gen.entity Repo Entity plural_snake id=uuid field=field_name:type --sref=reference --store=ecto
  example: mix nz.gen.entity Users User users id=uuid field=name:string field=email:string field=password:string --store=ecto --live
  use --no-live to prevent liveview generation
  """
  use Mix.Task
  @shortdoc "Setup new Entities"
  @author Application.compile_env(Mix.Project.config()[:app], :author, "General")
  @org Application.compile_env(Mix.Project.config()[:app], :group, "General")
  @ecto_types ["integer", "float", "string", "boolean", "binary", "date", "time", "naive_datetime", "utc_datetime", "utc_datetime_usec", "uuid", "map", "array", "decimal", "json", "jsonb", "any"]

  def run([context_name, entity_name, table_name | params]) do
    create_entity(context_name, entity_name, table_name, params)
  end

  def create_entity(context_name, entity_name, table_name, params) do
    app_name = Mix.Project.config()[:app] |> Atom.to_string()

    repo_snake = Macro.underscore(context_name)
    entity_snake = Macro.underscore(entity_name)
    repo_filename = "lib/#{app_name}/#{repo_snake}.ex" |> IO.inspect
    entity_filename = "lib/#{app_name}/#{repo_snake}/#{entity_snake}.ex"
    File.mkdir_p("lib/#{app_name}/#{repo_snake}")
    with false <- File.exists?(repo_filename) && {:error, "Repo exists: #{repo_filename}"},
         false <- File.exists?(entity_filename) && {:error, "Entity exists: #{entity_filename}"},
         {:ok, {context_contents, entity_contents}} <- entity_template(context_name, entity_name, params) do
      with :ok <- File.write(repo_filename, context_contents) do
        IO.puts("#{repo_filename} Generated")

        with :ok <- File.write(entity_filename, entity_contents) do
          IO.puts("#{entity_filename} Generated")


          # app_name = app_name()
          live = Enum.find_value(params, fn
            "--live" -> :live
            "--no-live" -> :no_live
            _ -> nil
          end)

          params = prep_params(params)
          fields = extract_fields(params[:field], params[:field_meta])
          storage = extract_storage(params[:store])

          unless live == :no_live do
            add_live(context_name, entity_name, table_name, fields)
          else
            # Ecto Setup
            if storage[:ecto] do
              add_ecto(context_name, entity_name, table_name, fields)
            end
          end
        else
          error -> IO.inspect(error, label: "Error")
        end
      else
        error -> IO.inspect(error, label: "Error")
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

#  defp entity_name(name, _) do
#    String.split(name, ".")
#    |> Enum.map(&String.capitalize(&1))
#    |> Enum.join(".")
#  end

  defp prep_params(params) do
    Enum.group_by(params, fn param ->
      cond do
        String.starts_with?(param, "--sref=") -> :sref
        String.starts_with?(param, "field=") -> :field
        String.starts_with?(param, "field.") -> :field_meta
        String.starts_with?(param, "id=") -> :id
        String.starts_with?(param, "--store=") -> :store
        :else -> :misc
      end
    end)
  end

  defp extract_sref(params) do
    Enum.find_value(params, fn param ->
      case String.split(param, "=") do
        ["--sref", x] -> x
        _ -> nil
      end
    end)
  end

  defp extract_id(nil), do: nil
  defp extract_id(params) do
    Enum.map(
      params,
      fn
        "id=" <> f ->
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

  defp extract_field_meta(field, meta)
  defp extract_field_meta(_, nil), do: []
  defp extract_field_meta(field, meta) do
    Enum.map(
      meta,
      fn
        "field." <> f ->
          cond do
            String.starts_with?(f, field <> ".") ->
              f = String.trim_leading(f, field <> ".")
              case String.split(f, "=") do
                [name] -> {String.downcase(name), "true"}
                [name | value] -> {String.downcase(name), Enum.join(value, "=")}
                _ -> nil
              end
            :else -> nil
          end
        _ ->
          nil
      end
    )
    |> Enum.reject(&is_nil/1)
  end

  defp extract_fields(params, meta)
  defp extract_fields(nil, _), do: []
  defp extract_fields(params, meta) do
    Enum.map(
      params,
      fn
        "field=" <> f ->
          case String.split(f, ":") do
            [name] ->
              settings = extract_field_meta(name, meta)
              {:field, {name, nil, settings}}
            [name| type] ->
              settings = extract_field_meta(name, meta)
              type = Enum.join(type, ":")
              type = String.trim(type)
              {:field, {name, type, settings}}
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
        "--store=ecto" -> {:ecto, :storage}
        "--store=redis" -> {:redis, :storage}
        "--store=mnesia" -> {:mnesia, :storage}
        _ -> nil
      end
    )
    |> Enum.filter(& &1)
  end

  defp add_live(context_name, entity_name, table, fields) do
    ecto = Enum.map(fields,
             fn
               {_, {field, "{:array," <> _ = type, _settings}} ->
                 "#{field}:#{type}"
               {_, {field, type, _settings}} when type in @ecto_types ->
                 "#{field}:#{type}"
               {_, {field, type, _settings}} ->
               try do
                 m = String.to_existing_atom("Elixir.#{type}")
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
             fn
               {_, {field, "{:array," <> _ = type, _settings}} ->
                 "#{field}:#{type}"
               {_, {field, type, _settings}} when type in @ecto_types ->
                 "#{field}:#{type}"
               {_, {field, type, _settings}} ->
               try do
                 m = String.to_existing_atom("Elixir.#{type}")
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
    params = prep_params(params) |> IO.inspect
    # Sref, Fields, Storage
    sref = extract_sref(params[:sref])
    fields = extract_fields(params[:field], params[:field_meta])
    id_type = extract_id(params[:id]) || ":uuid"
    storage = extract_storage(params[:store])

    # Ecto Setup
    # storage[:ecto] && add_ecto(name, fields)

    # Payload Snippet
    entity_fields =
      Enum.map(fields, fn {_, {field, type, settings}} ->
        default = Enum.find_value(settings, "nil", fn
          {"default", x} ->
            x
            |> String.split("\n")
            |> Enum.join("\n    " <> String.duplicate(" ", String.length("field :#{field}, ")))
          _ -> nil
        end)

        attributes = Enum.map(settings, fn
          {"default", _} -> nil
          {type, value} ->
            value = value
                    |> String.split("\n")
                    |> Enum.join("\n    " <> String.duplicate(" ", String.length("@#{type} ")))
            "@#{type} #{value}"
        end)
                     |> Enum.reject(&is_nil/1)
                     |> Enum.join("\n")
        attributes = attributes != "" && attributes <> "\n" || ""
        ltype = type && String.downcase(type)
        cond do
          ltype in @ecto_types ->
            "#{attributes}field :#{field}, #{default}, :#{ltype}"
          is_nil(ltype) ->
            cond do
              default != "nil" -> "#{attributes}field :#{field}, #{default}"
              :else -> "#{attributes}field :#{field}"
            end
          :else ->
            "#{attributes}field :#{field}, #{default}, #{type}"
        end |> String.split("\n")
      end)
      |> List.flatten()
      |> Enum.join("\n    ")

    entity_persistence =
      Enum.map(
        storage,
        fn {store, settings} ->
          "@persistence {#{inspect(store)}, #{inspect(settings)}}"
        end
      )
      |> Enum.join("\n     ")

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
          id #{id_type}
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
        def list_#{plural_snake}(context, options \\\\ []) do
          # list(context)
          []
        end

        @doc \"""
        Gets a single #{singular_snake}.

        \"""
        def get_#{singular_snake}(id, context, options \\\\ []), do: get(id, context, options)

        @doc \"""
        Creates a #{singular_snake}.
        \"""
        def create_#{singular_snake}(#{singular_snake}, context, options \\\\ []) do
          create(#{singular_snake}, context, options)
        end

        @doc \"""
        Updates a #{singular_snake}.
        \"""
        def update_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, attrs, context, options \\\\ []) do
          #{singular_snake}
          |> change_#{singular_snake}(attrs)
          |> update(context, options)
        end

        @doc \"""
        Deletes a #{singular_snake}.
        \"""
        def delete_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, context, options \\\\ []) do
          delete(#{singular_snake}, context, options)
        end

        @doc \"""
        Returns an Changeset for tracking #{singular_snake} changes.
        \"""
        def change_#{singular_snake}(%#{entity_name}{} = #{singular_snake}, attrs \\\\ %{}) do
          # NYI: Implement custom changeset logic here.
          #{singular_snake}
        end
      end
    """
    {:ok, {repo, entity}}
  end
end
