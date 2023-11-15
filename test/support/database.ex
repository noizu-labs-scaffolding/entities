use Amnesia
defdatabase NoizuEntityTestDb do

  deftable BizBopTable, [:identifier, :created_on, :entity], index: [:created_on] do
    @type t :: %__MODULE__{identifier: any, created_on: integer, entity: any}
  end

end
