-- basket/src/node.lua
-- Basket nodes
-- Copyright (c) 2022, 2024-2025  1F616EMO
-- SPDX-LICENSE-IDENTIFIER: LGPL-2.1-OR-LATER

local S = core.get_translator("basket")

basket.prohibited_items = {
    -- Matryoshka doll
    ["basket:basket"] = true,
    -- Digtron crates
    ["digtron:loaded_crate"] = true,
    ["digtron:loaded_locked_crate"] = true,
}

local log_non_player_actions = core.settings:get_bool("log_non_player_actions", false)
local function log(player, details)
    local msg = player:get_player_name()
    if player.is_fake_player or not player:is_player() then
        if not log_non_player_actions then
            return
        end
        msg = msg .. "(" .. (type(player.is_fake_player) == "string"
            and player.is_fake_player or "*") .. ")"
    end
    return core.log("action", msg .. " " .. details)
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
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        inv:set_size("main", 32)
        meta:set_string("formspec", basket.formspec)
        meta:set_string("infotext", S("Portable Basket") .. "\n" ..
            S("Occupied: @1/@2", 0, 32))
    end,
    after_place_node = function(pos, _, itemstack)
        local basket_data = basket.get_basket_from_item(itemstack)
        if not basket_data then return end
        basket.set_basket_node_data(pos, basket_data)
    end,
    on_rightclick = function(pos, _, _, itemstack)
        basket.update_basket_node_meta(pos)
        return itemstack
    end,
    on_receive_fields = function(pos, _, fields, sender)
        if fields["teacher"] and core.get_modpath("teacher_core") and sender:is_player() then
            teacher.simple_show(sender, "basket:basket_basic")
            return
        end
        local name = sender:get_player_name()
        if core.is_protected(pos, name) then
            core.record_protection_violation(pos, name)
            return
        end
        local meta = core.get_meta(pos)
        local description = fields["infotext"] or ""
        if not fields["btn"] then return end
        meta:set_string("basket_description", description)
        basket.update_basket_node_meta(pos)
    end,
    preserve_metadata = function(pos, _, _, drops)
        local basket_data = basket.get_basket_from_node(pos)
        local basket_item =
            basket_data
            and basket.get_basket_itemstack(basket_data)
            or ItemStack("basket:basket_craftitem")
        drops[1] = basket_item
    end,
    groups = {
        choppy = 2,
        oddly_breakable_by_hand = 2,
        flammable = 2,
        tubedevice = 1,
        tubedevice_receiver = 1,
        not_in_creative_inventory = 1,
        basket = 1,
    },
    allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
        local name = player:get_player_name()
        if core.is_protected(pos, name) then
            core.record_protection_violation(pos, name)
            return 0
        end
        return count
    end,
    allow_metadata_inventory_put = function(pos, _, _, stack, player)
        local name = player:get_player_name()
        if core.is_protected(pos, name) then
            core.record_protection_violation(pos, name)
            return 0
        end
        if basket.prohibited_items[stack:get_name()] then return 0 end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, _, _, stack, player)
        local name = player:get_player_name()
        if core.is_protected(pos, name) then
            core.record_protection_violation(pos, name)
            return 0
        end
        return stack:get_count()
    end,
    on_metadata_inventory_move = function(pos, _, _, _, _, _, player)
        log(player, "moves stuff in basket at " .. core.pos_to_string(pos))
        basket.update_basket_node_meta(pos)
    end,
    on_metadata_inventory_put = function(pos, _, _, stack, player)
        log(player, "moves " .. stack:get_name() .. " " .. stack:get_count()
            .. " to basket at " .. core.pos_to_string(pos))
        basket.update_basket_node_meta(pos)
    end,
    on_metadata_inventory_take = function(pos, _, _, stack, player)
        log(player, "takes " .. stack:get_name() .. " " .. stack:get_count()
            .. " from basket at " .. core.pos_to_string(pos))
        basket.update_basket_node_meta(pos)
    end,
    stack_max = 1,
    on_blast = function() end,
    on_drop = function(itemstack) return itemstack end,
    sounds = default.node_sound_wood_defaults(),
}

if core.get_modpath("pipeworks") then
    local old_on_construct = node_def.on_construct
    node_def.on_construct = function(pos)
        old_on_construct(pos)
        pipeworks.scan_for_tube_objects(pos)
    end
    node_def.tube = {
        insert_object = function(pos, _, stack)
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            local rtn = inv:add_item("main", stack)
            basket.update_basket_node_meta(pos)
            return rtn
        end,
        can_insert = function(pos, _, stack)
            if basket.prohibited_items[stack:get_name()] then return false end
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:room_for_item("main", stack)
        end,
        input_inventory = "main",
        connect_sides = { left = 1, right = 1, back = 1, bottom = 1, top = 1, front = 1 }
    }
    node_def.on_destruct = pipeworks.scan_for_tube_objects
    node_def.on_rotate = pipeworks.on_rotate
end

core.register_node("basket:basket", table.copy(node_def))
node_def.groups.not_in_creative_inventory = nil
core.register_node("basket:basket_craftitem", { -- Empty Baskets: Skip on_place checks
    description = S("Portable Basket (Empty)"),
    tiles = node_def.tiles,
    on_construct = function(pos)
        local node = core.get_node(pos)
        node.name = "basket:basket"
        core.swap_node(pos, node)
        node_def.on_construct(pos)
    end,
    node_placement_prediction = "basket:basket",
    sounds = node_def.sounds,
    groups = node_def.groups,
})

if core.global_exists("xcompat") then
    core.register_craft({
        recipe = {
            { "group:wood", xcompat.materials.string, "group:wood" },
            { "group:wood", "",                       "group:wood" },
            { "group:wood", "group:wood",             "group:wood" },
        },
        output = "basket:basket_craftitem"
    })
end
