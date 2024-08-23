-- basket/init.lua
-- A portable basket for carrying large amount of items (= Shulker Boxes)
--[[
    MIT License

    Copyright (c) 2022, 2024  1F616EMO

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

local S = minetest.get_translator("basket")
local F = minetest.formspec_escape
local FS = function(...) return F(S(...)) end

local formspec = "size[8,10]" ..
    "label[0,0.2;" .. FS("Name:") .. "]" ..
    "field[1.3,0.3;5,1;infotext;;${basket_description}]" ..
    "button[7,0;1,1;btn;" .. FS("OK") .. "]" ..
    "list[context;main;0,1.3;8,4;]" ..
    "list[current_player;main;0,5.85;8,1;]" ..
    "list[current_player;main;0,7.08;8,3;8]" ..
    "listring[context;main]" ..
    "listring[current_player;main]" ..
    default.get_hotbar_bg(0, 5.85)

local teacher_enabled = false
if minetest.get_modpath("teacher_core") then
    teacher_enabled = true

    teacher.register_turorial("basket:basket_basic", {
        title = S("Portable Baskets"),
        triggers = {
            {
                name = "approach_node",
                nodenames = { "basket:basket" },
            },
            {
                name = "obtain_item",
                itemname = "basket:basket_craftitem",
            },
            {
                name = "obtain_item",
                itemname = "basket:basket",
            },
        },

        {
            texture = "basket_teacher_1.png",
            text = {
                S("Baskets are portable storage nodes. They act like normal chests and keep their contents when dug."),
                S("You can rename a basket. Type in the name, then click on \"@1\".", S("OK")),
            }
        },
        {
            texture = "basket_teacher_2.png",
            text = S("You cannot stack baskets with occupied slots on each other, "
                .. "nor can you put such baskets inside another one."),
        },
    })

    formspec = formspec .. "button[6,0;1,1;teacher;?]"
end

-- Deny these items to reduce itemstring size
local prohibited_items = {
    -- Matryoshka doll
    ["basket:basket"] = true,
    -- Digtron crates
    ["digtron:loaded_crate"] = true,
    ["digtron:loaded_locked_crate"] = true,
}

local scan_for_tube_objects = minetest.get_modpath("pipeworks") and pipeworks.scan_for_tube_objects or function() end
local occupied_translated_match = "\n" .. string.char(0x1b) .. "(T@basket)Occupied: " .. string.char(0x1b) .. "F"

local function count_occupied_slots(inv, listname)
    local list = inv:get_list(listname)
    local count = 0
    for _, item in ipairs(list) do
        if not item:is_empty() then
            count = count + 1
        end
    end
    return count
end

local function get_node_description(meta, fallback)
    local description = meta:get_string("basket_description")
    if description == "" then
        local old_description = meta:get_string("infotext")
        if not string.find(old_description, occupied_translated_match, 1, true) then
            description = old_description
            meta:set_string("basket_description", description)
        end
    end
    return description == "" and fallback or description
end

local function update_node_meta(meta, inv)
    meta:set_string("formspec", formspec)

    local description = get_node_description(meta, S("Portable Basket"))

    inv = inv or meta:get_inventory()
    local occupied_slots = count_occupied_slots(inv, "main")
    meta:set_string("infotext", description .. "\n" ..
        S("Occupied: @1/@2", occupied_slots, inv:get_size("main")))
end

local function get_stack_description(meta)
    local description = meta:get_string("basket_description")
    if description == "" then
        local old_description = meta:get_string("description")
        if not string.find(old_description, occupied_translated_match, 1, true) then
            description = old_description
        end
    end
    return description
end

local node_def = {
    description = S("Portable Basket"),
    tiles = {
        "cardboard_box_inner.png^basket_top.png",
        "basket_inner.png",
        "basket_side.png",
        "basket_side.png",
        "basket_side.png",
        "basket_side.png"
    },
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        inv:set_size("main", 32)
        meta:set_string("formspec", formspec)
        meta:set_string("formspec", formspec)
        meta:set_string("infotext", S("Portable Basket") .. "\n" ..
            S("Occupied: @1/@2", 0, 32))
    end,
    on_place = function(itemstack, placer, pointed_thing)
        local stack = itemstack:peek_item(1)
        local pos
        itemstack, pos = minetest.item_place(itemstack, placer, pointed_thing)

        if not pos then return itemstack end
        local stack_meta = stack:get_meta()
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local inv_table = minetest.deserialize(stack_meta:get_string("inv"))
        if inv_table then
            inv:set_list("main", inv_table)
        end
        local description = get_stack_description(stack_meta)
        meta:set_string("basket_description", description)
        update_node_meta(meta, inv)

        return itemstack
    end,
    on_rightclick = function(pos, _, _, itemstack)
        local meta = minetest.get_meta(pos)
        update_node_meta(meta)
        return itemstack
    end,
    on_receive_fields = function(pos, _, fields, sender)
        if fields["teacher"] and teacher_enabled and sender:is_player() then
            teacher.simple_show(sender, "basket:basket_basic")
            return
        end
        local name = sender:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return
        end
        local meta = minetest.get_meta(pos)
        local description = fields["infotext"] or ""
        if not fields["btn"] then return end
        meta:set_string("basket_description", description)
        update_node_meta(meta)
    end,
    groups = {
        choppy = 2,
        oddly_breakable_by_hand = 2,
        flammable = 2,
        tubedevice = 1,
        tubedevice_receiver = 1,
        not_in_creative_inventory = 1,
    },
    on_dig = function(pos, _, digger)
        if not digger:is_player() then return false end
        local digger_inv = digger:get_inventory()
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local name = digger:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return false
        end

        if inv:is_empty("main") then
            if not minetest.is_creative_enabled(name)
                or not digger_inv:contains_item("main", "basket:basket_craftitem") then
                local stack = ItemStack("basket:basket_craftitem")
                if not digger_inv:room_for_item("main", stack) then
                    return false
                end
                digger_inv:add_item("main", stack)
            end
            minetest.set_node(pos, { name = "air" })
            scan_for_tube_objects(pos)
            return true
        end

        local stack = ItemStack("basket:basket")
        local stack_meta = stack:get_meta()
        if not digger_inv:room_for_item("main", stack) then
            return false
        end

        local inv_table_raw = inv:get_list("main")
        local inv_table = {}
        local inv_occupied = 0
        for x, y in ipairs(inv_table_raw) do
            inv_table[x] = y:to_string()
            if not y:is_empty() then
                inv_occupied = inv_occupied + 1
            end
        end
        inv_table = minetest.serialize(inv_table)

        do -- Check the serialized table to avoid accidents
            local inv_table_des = minetest.deserialize(inv_table)
            if not inv_table_des then
                -- If the table is too big, the serialize result might be nil.
                -- That was a bug found in advtrains and is now solved.
                -- I'm not gonna use such a complex way to serialize the inventory,
                -- so just reject to dig the node.
                return false
            end
        end

        stack_meta:set_string("inv", inv_table)
        stack_meta:set_string("basket_description", get_node_description(meta))
        stack_meta:set_string("description", get_node_description(meta, S("Portable Basket")) .. "\n" ..
            S("Occupied: @1/@2", inv_occupied, inv:get_size("main")))
        digger_inv:add_item("main", stack)
        minetest.set_node(pos, { name = "air" })
        scan_for_tube_objects(pos)
        return true
    end,
    allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
        local name = player:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        end
        return count
    end,
    allow_metadata_inventory_put = function(pos, _, _, stack, player)
        local name = player:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        end
        if prohibited_items[stack:get_name()] then return 0 end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, _, _, stack, player)
        local name = player:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return 0
        end
        return stack:get_count()
    end,
    on_metadata_inventory_move = function(pos)
        update_node_meta(minetest.get_meta(pos))
    end,
    on_metadata_inventory_put = function(pos)
        update_node_meta(minetest.get_meta(pos))
    end,
    on_metadata_inventory_take = function(pos)
        update_node_meta(minetest.get_meta(pos))
    end,
    stack_max = 1,
    on_blast = function() end,
    on_drop = function(itemstack) return itemstack end,
	sounds = default.node_sound_wood_defaults(),
}
default.set_inventory_action_loggers(node_def, "basket")

if minetest.get_modpath("pipeworks") then
    local old_on_construct = node_def.on_construct
    node_def.on_construct = function(pos)
        old_on_construct(pos)
        pipeworks.scan_for_tube_objects(pos)
    end
    node_def.tube = {
        insert_object = function(pos, _, stack)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            local rtn = inv:add_item("main", stack)
            update_node_meta(meta, inv)
            return rtn
        end,
        can_insert = function(pos, _, stack)
            if prohibited_items[stack:get_name()] then return false end
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:room_for_item("main", stack)
        end,
        input_inventory = "main",
        connect_sides = { left = 1, right = 1, back = 1, bottom = 1, top = 1, front = 1 }
    }
    node_def.on_destruct = pipeworks.scan_for_tube_objects
    node_def.on_rotate = pipeworks.on_rotate
end

minetest.register_node("basket:basket", node_def)
minetest.register_node("basket:basket_craftitem", { -- Empty Baskets: Skip on_place checks
    description = S("Portable Basket"),
    tiles = node_def.tiles,
    on_construct = function(pos)
        local node = minetest.get_node(pos)
        node.name = "basket:basket"
        minetest.swap_node(pos, node)
        node_def.on_construct(pos)
    end,
    node_placement_prediction = "basket:basket",
	sounds = default.node_sound_wood_defaults(),
})

if minetest.get_modpath("farming") then
    minetest.register_craft({
        recipe = {
            { "group:wood", "farming:string", "group:wood" },
            { "group:wood", "",               "group:wood" },
            { "group:wood", "group:wood",     "group:wood" },
        },
        output = "basket:basket_craftitem"
    })
end
