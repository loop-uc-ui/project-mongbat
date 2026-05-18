-- Creates the Mongbat global tables. Must load before all other Mongbat
-- sub-modules so they can assign into it at file-load time.
Mongbat = {}

-- Private engine-entry-point table. Sub-systems write into _Mongbat.Systems
-- at file-load time; Mongbat.lua assigns the lifecycle callbacks (.OnInitialize,
-- .OnUpdate, .OnShutdown) without replacing the table.
_Mongbat = {}
_Mongbat.Systems = {}
