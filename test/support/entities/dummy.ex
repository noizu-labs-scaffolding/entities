
defmodule Noizu.Support.Entity.ETS.DummyRepo do

end

defmodule Noizu.Support.Entity.ETS.DummyRecord do
  defstruct [
    identifier: nil,
    name: nil,
    title: nil,
    title2: nil,
    description: nil,
    json_template_specific: nil,
    json_template_specific2: nil,
    created_on: nil,
    modified_on: nil,
    deleted_on: nil,
  ]
end
