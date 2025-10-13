-- basket/init.lua
-- A portable basket for carrying large amount of items (= Shulker Boxes)
-- Copyright (c) 2022, 2024-2025  1F616EMO
-- SPDX-LICENSE-IDENTIFIER: LGPL-2.1-OR-LATER

local S = core.get_translator("basket")
local F = core.formspec_escape
local FS = function(...) return F(S(...)) end

basket = {}

basket.formspec = "size[8,10]" ..
    "label[0,0.2;" .. FS("Name:") .. "]" ..
    "field[1.3,0.3;5,1;infotext;;${basket_description}]" ..
    "button[7,0;1,1;btn;" .. FS("OK") .. "]" ..
    "list[context;main;0,1.3;8,4;]" ..
    "list[current_player;main;0,5.85;8,1;]" ..
    "list[current_player;main;0,7.08;8,3;8]" ..
    "listring[context;main]" ..
    "listring[current_player;main]" ..
    (core.global_exists("default") and default.get_hotbar_bg(0, 5.85) or "")

local MP = core.get_modpath("basket")
dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "api.lua")
dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "teacher.lua")
dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. "node.lua")
