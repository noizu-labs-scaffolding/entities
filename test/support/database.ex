use Amnesia
defdatabase NoizuEntityTestDb do

  deftable BizBops.BizBopTable, [:id, :inserted_at, :entity], index: [:inserted_at] do
    @type t :: %__MODULE__{id: any, inserted_at: integer, entity: any}
  end

end
