-- basket/init.lua
-- A portable basket for carrying large amount of items (= Shulker Boxes)
-- Copyright (c) 2022, 2024-2025  1F616EMO
-- SPDX-LICENSE-IDENTIFIER: LGPL-2.1-OR-LATER

local S = core.get_translator("basket")
local F = core.formspec_escape
local FS = function(...) return F(S(...)) end
local MP = core.get_modpath("basket")

basket = {}

dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "api.lua")
dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "node.lua")

if core.get_modpath("teacher_core") then
    dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "teacher.lua")
end

