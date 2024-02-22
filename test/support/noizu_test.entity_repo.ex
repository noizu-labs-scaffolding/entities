defmodule NoizuTest.EntityRepo do
  def create(entity, context, options \\ nil) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :create, [entity, context, options])
  end

  def update(entity, context, options \\ nil) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :update, [entity, context, options])
  end

  def delete(entity, context, options \\ nil) do
    r = entity.__struct__.__noizu_meta__()[:repo]
    apply(r, :delete, [entity, context, options])
  end
end
