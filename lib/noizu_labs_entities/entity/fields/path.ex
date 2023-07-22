defmodule Noizu.Entity.Path do
  @derive Noizu.EntityReference.Protocol
  defstruct [
    path: nil,
    materialized_path: nil,
    matrix: nil,
    depth: nil,
  ]

  @identity_matrix %{
    a11: 1,
    a12: 0,
    a21: 0,
    a22: 1
  }

  def type_as_entity(this, _, _), do: {:ok, this}
  def stub(), do: {:ok, %__MODULE__{}}


  def parent_path(nil), do: nil
  def parent_path(%{__struct__: __MODULE__} = this) do
    new(Enum.slice(this.path, 0..-2))
  end

  def path_string(nil), do: nil
  def path_string(%{__struct__: __MODULE__} = this) do
    Enum.join(this.path, ".")
  end

  #---------------------------
  #
  #---------------------------
  def position_matrix(position) when is_integer(position) do
    i = position + 1
    %{
      a11: i,
      a12: -1,
      a21: 1,
      a22: 0
    }
  end

  #---------------------------
  #
  #---------------------------
  def multiply_matrix(%{a11: a11, a12: a12, a21: a21, a22: a22}, %{a11: b11, a12: b12, a21: b21, a22: b22}) do
    %{
      a11: (a11 * b11 + a12 * b21),
      a12: (a11 * b12 + a12 * b22),
      a21: (a21 * b11 + a22 * b21),
      a22: (a21 * b12 + a22 * b22),
    }
  end

  #---------------------------
  #
  #---------------------------
  def leaf_node(%{a11: a11, a12: a12, a21: _a21, a22: _a22}) do
    Integer.floor_div(a11, -a12)
  end

  #---------------------------
  #
  #---------------------------
  def convert_path_to_matrix([]), do: @identity_matrix
  def convert_path_to_matrix(path) when is_list(path) do
    Enum.reduce(
      path,
      @identity_matrix,
      fn (position, path) ->
        multiply_matrix(path, position_matrix(position))
      end
    )
  end


  #---------------------------
  # child
  #---------------------------
  def child(path, position) do
    np = path.path ++ [position]
    %__MODULE__{
      depth: path.depth + 1,
      path: np,
      materialized_path: convert_path_to_tuple(np),
      matrix:  multiply_matrix(path.matrix, position_matrix(position))
    }
  end

  #---------------------------
  #
  #---------------------------
  def convert_matrix_to_path(m) do
    convert_matrix_to_path(m, [])
  end

  def convert_matrix_to_path(%{a11: 1, a12: 0, a21: 0, a22: 1}, acc) do
    Enum.reverse(acc)
  end

  def convert_matrix_to_path(m, acc) do
    if (m.a22 == 0) do
      Enum.reverse(acc ++ [m.a11 - 1])
    else
      if (length(acc) < 1024) do
        l = leaf_node(m)
        a11 = -m.a12
        a21 = -m.a22
        a12 = (m.a11 - (a11 * (l + 1)))
        a22 = (m.a21 - (a21 * (l + 1)))
        convert_matrix_to_path(%{a11: a11, a12: a12, a21: a21, a22: a22}, acc ++ [l])
      else
        {:error, acc}
      end
    end
  end

  #---------------------------
  #
  #---------------------------
  def convert_tuple_to_path(path) when is_tuple(path) do
    convert_tuple_to_path(path, [])
  end

  def convert_tuple_to_path({}, acc), do: acc
  def convert_tuple_to_path({a}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, {}}, acc), do: acc ++ [a]

  def convert_tuple_to_path({a, b}, acc), do: convert_tuple_to_path(b, acc ++ [a])

  #---------------------------
  #
  #---------------------------
  def convert_path_to_tuple(path) when is_list(path) do
    path
    |> Enum.reverse()
    |> Enum.reduce({}, &({&1, &2}))
  end

  #---------------------------
  #
  #---------------------------
  def new(%{path_a11: a11, path_a12: a12, path_a21: a21, path_a22: a22}) do
    new(%{a11: a11, a12: a12, a21: a21, a22: a22})
  end

  def new(%{a11: a11, a12: a12, a21: a21, a22: a22} = _m) when a12 > 0 and a22 > 0 do
    new(%{a11: a11, a12: -a12, a21: a21, a22: -a22})
  end

  def new(%{a11: _a11, a12: _a12, a21: _a21, a22: _a22} = m)  do
    new(convert_matrix_to_path(m))
  end

  def new(path) when is_tuple(path) do
    new(convert_tuple_to_path(path))
  end

  def new(path) when is_list(path) do
    %__MODULE__{
      depth: length(path),
      path: path,
      materialized_path: convert_path_to_tuple(path),
      matrix: convert_path_to_matrix(path)
    }
  end

  def new("") do
    %__MODULE__{
      depth: 0,
      path: [],
      materialized_path: {},
      matrix: @identity_matrix
    }
  end
  def new(path) when is_bitstring(path) do
    path
    |> String.split(".")
    |> Enum.map(&(String.to_integer(&1)))
    |> new()
  end


end


defimpl Noizu.Entity.Store.Ecto.Protocol, for: [Noizu.Entity.Path] do
  require  Noizu.Entity.Meta.Persistence
  require  Noizu.Entity.Meta.Field

  def as_record(_,_,_,_), do: {:error, :not_supported}
  def from_record(_,_,_,_), do: {:error, :not_supported}
  def persist(_,_,_,_,_), do: {:error, :not_supported}

  def field_as_record(
        field,
        Noizu.Entity.Meta.Field.field_settings(name: name, store: field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: store, table: table)
      ) do
    name = field_store[table][:name] || field_store[store][:name] || name
    [
      {:"#{name}_depth", field.depth},
      {:"#{name}_a11", field.matrix.a11},
      {:"#{name}_a12", field.matrix.a12},
      {:"#{name}_a21", field.matrix.a21},
      {:"#{name}_a22", field.matrix.a22},
    ]
  end

  def field_from_record(
        _,
        _record,
        Noizu.Entity.Meta.Field.field_settings(name: _name, store: _field_store),
        Noizu.Entity.Meta.Persistence.persistence_settings(store: _store, table: _table)
      ) do
    #as_name = field_store[table][:name] || field_store[store][:name] || name
    # We need to do a universal lookup
    {:error, :pending}
  end
end
