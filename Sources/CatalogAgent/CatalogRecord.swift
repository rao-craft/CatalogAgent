//  WHAT: The record an app finds the package by: one entry in `__DATA_CONST,__granite`, read by
//        `GraniteRoster.discovered()` with nothing listed by hand.

import GraniteAgents

@used @section("__DATA_CONST,__granite")
let catalogRecord: GraniteRoster.Record = { GraniteRoster.record(CatalogAgent.self) }
