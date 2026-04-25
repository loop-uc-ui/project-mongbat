---@diagnostic disable: undefined-global
-- Creates the Mongbat global table. Must load before all other Mongbat
-- sub-modules so they can assign into it at file-load time.
Mongbat = {}
