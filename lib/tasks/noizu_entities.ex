defmodule Mix.Tasks.Nz.Gen.Entity do
  use Mix.Task
  @shortdoc "Setup new Entities"
  @author Application.compile_env(Mix.Project.config()[:app], :author, "General")
  @org Application.compile_env(Mix.Project.config()[:app], :group, "General")

  def run([name | params]) do
    create_entity(name, params)
  end

  def create_entity(name, params) do
    IO.inspect params, label: "Params"
    app_name = Mix.Project.config()[:app] |> Atom.to_string()

    filename = "lib/#{app_name}_entities/#{name}.ex"
    content = entity_template(name, params)
    with :ok <- File.write(filename, content) do
      IO.puts "Generated"
    end
  end


  defp app_name() do
    Mix.Project.config()[:app]
    |> Atom.to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("")
  end

  defp entity_name(name,_) do
    String.split(name, ".")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(".")
  end

  defp prep_params(params) do
    Enum.group_by(params, fn(param) ->
      cond do
        String.starts_with?(param, "sref=") -> :sref
        String.starts_with?(param, "field=") -> :field
        String.starts_with?(param, "store=") -> :store
        :else -> :misc
      end
    end)
  end

  defp extract_sref(params) do
    Enum.find_value(params, fn(param) ->
      case String.split(param, "=") |> IO.inspect(label: "Split") do
        ["sref", x] -> x
        _ -> nil
      end
    end)
  end

  defp extract_fields(nil), do: []
  defp extract_fields(params) do
    Enum.map(params,
      fn
        ("field=" <> f) ->
          case String.split(f, ":") do
            [name, type] ->
              {:field, {name, type}}
          end
        (_) -> nil
      end) |> Enum.filter(&(&1))
  end

  defp extract_storage(nil), do: []
  defp extract_storage(params) do
    Enum.map(params,
      fn
        ("store=ecto") -> {:ecto, :storage}
        ("store=redis") -> {:redis, :storage}
        ("store=mnesia") -> {:mnesia, :storage}
        (_) -> nil
      end) |> Enum.filter(&(&1))
  end

  defp add_ecto(name, fields) do
    ecto = Enum.map(fields, fn {_,{field, type}} -> "#{field}:#{type}" end)
    ecto = ["Schema" <> "." <> name, Macro.underscore(name)|  ecto]
    Mix.Tasks.Phx.Gen.Schema.run(ecto)
  end

  def entity_template(name, params) do
    app_name = app_name()
    name = entity_name(name, params)
    sm = app_name <> "." <> name
    params = prep_params(params)
    # Sref, Fields, STorage
    sref = extract_sref(params[:sref])
    fields = extract_fields(params[:field])
    storage = extract_storage(params[:store])

    # Ecto Setup
    storage[:ecto] && add_ecto(name, fields)

    # Payload Snippet
    entity_fields =
      Enum.map(fields, fn({_,{field, type}}) -> "field :#{field}" end)
      |> Enum.join("\n    ")
    entity_persistence = Enum.map(storage,
                           fn({store, settings}) ->
                             "@persistence {#{inspect store}, #{inspect settings}}"
                           end) |> Enum.join("\n   ")

    entity = """
      #-------------------------------------------------------------------------------
      # Author: #{@author}
      # Copyright (C) #{DateTime.utc_now().year} #{@org} All rights reserved.
      #-------------------------------------------------------------------------------

      defmodule #{sm} do
        use Noizu.Entities

        @vsn 1.0
        #{ sref && "@sref \"#{sref}\"" || "" }
        #{entity_persistence}
        def_entity do
          identifier :integer
          #{entity_fields}
        end
      end
    """
  end
end
