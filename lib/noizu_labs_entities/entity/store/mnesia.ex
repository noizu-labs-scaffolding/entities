#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2023 Noizu Labs Inc. All rights reserved.
#-------------------------------------------------------------------------------

defprotocol Noizu.Entity.Store.Mnesia.Protocol do
    def as_record(entity, settings, context, options)
    def from_record(record, settings, context, options)
    def persist(entity, type, settings, context, options)
end