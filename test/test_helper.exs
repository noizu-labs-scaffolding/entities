Mimic.copy(Noizu.Entity.Store.Dummy.StorageLayer)
Amnesia.start
NoizuEntityTestDb.create() |> IO.inspect
NoizuEntityTestDb.BizBopTable.create(disk: [node()])
ExUnit.start()
