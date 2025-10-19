-- basket/src/api.lua
-- Basket APIs
-- Copyright (c) 2022, 2024-2025  1F616EMO
-- SPDX-LICENSE-IDENTIFIER: LGPL-2.1-OR-LATER

local S = core.get_translator("basket")

local occupied_translated_match = "\n" .. string.char(0x1b) .. "(T@basket)Occupied: " .. string.char(0x1b) .. "F"

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

function basket.get_basket_from_node(pos)
    local node = core.get_node(pos)
    if node.name ~= "basket:basket" then
        return nil
    end

    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()

    local description = get_node_description(meta, "")
    local inv_table = inv:get_list("main")

    return {
        description = description,
        items = inv_table,
    }
end

function basket.get_basket_from_item(itemstack)
    local name = itemstack:get_name()
    if name == "basket:basket_craftitem" then
        local items = {}
        for i = 1, 32 do
            items[i] = ItemStack("")
        end
        return {
            description = "",
            items = items,
        }
    elseif name ~= "basket:basket" then
        return nil
    end

    local meta = itemstack:get_meta()
    local inv_table = core.deserialize(meta:get_string("inv"))
    for i, item in ipairs(inv_table) do
        inv_table[i] = ItemStack(item)
    end
    local description = get_node_description(meta, "")

    return {
        description = description,
        items = inv_table,
    }
end

function basket.set_basket_node_data(pos, basket_data)
    local node = core.get_node(pos)
    if node.name ~= "basket:basket" then
        return false
    end

    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()

    meta:set_string("basket_description", basket_data.description or "")
    meta:set_string("infotext", basket.get_basket_infotext(basket_data))
    inv:set_list("main", basket_data.items)

    return true
end

function basket.get_basket_itemstack(basket_data)
    if #basket_data.items == 0 then
        return ItemStack("basket:basket_craftitem")
    end

    local itemstack = ItemStack("basket:basket")
    local meta = itemstack:get_meta()
    local inv_table = {}
    for i, item in ipairs(basket_data.items) do
        inv_table[i] = item:to_string()
    end

    meta:set_string("inv", core.serialize(inv_table))
    meta:set_string("basket_description", basket_data.description or "")
    meta:set_string("description", basket.get_basket_infotext(basket_data))

    return itemstack
end

-- Internal, stability not guaranteed

function basket.get_basket_infotext(basket_data)
    local infotext = "\n"

    local occupied_slots = 0
    local item_counts = {}
    local items = {}
    for _, item in ipairs(basket_data.items) do
        if not item:is_empty() then
            occupied_slots = occupied_slots + 1

            local item_name = item:get_name()
            if not item_counts[item_name] then
                item_counts[item_name] = item:get_count()
                items[#items + 1] = item_name
            else
                item_counts[item_name] = item_counts[item_name] + item:get_count()
            end
        end
    end

    table.sort(items, function(a, b)
        return item_counts[a] > item_counts[b]
    end)

    infotext = infotext .. S("Occupied: @1/@2", occupied_slots, #basket_data.items)

    for i = 1, math.min(3, #items) do
        local item_def = core.registered_items[items[i]]
        local item_description = item_def and (item_def.short_description or item_def.description) or items[i]
        item_description = string.trim(string.split(item_description, "\n")[1])
        local count = item_counts[items[i]]

        infotext = infotext .. "\n" .. item_description .. " x" .. count
    end
    if #items > 3 then
        infotext = infotext .. "\n" .. S("... and more")
    end

    local description = basket_data.description ~= "" and basket_data.description or nil
    -- Auto description
    if not description then
        if #items == 1 then
            local item_def = core.registered_items[items[1]]
            local item_description = item_def and (item_def.short_description or item_def.description) or items[1]
            item_description = string.trim(string.split(item_description, "\n")[1])

            description = S("A basket of @1", item_description)
        else
            description = S("Portable Basket")
        end
    end

    return description .. infotext
end

function basket.update_basket_node_meta(pos)
    local basket_data = basket.get_basket_from_node(pos)
    if not basket_data then return end

    local meta = core.get_meta(pos)
    meta:set_string("formspec", basket.formspec)
    meta:set_string("infotext", basket.get_basket_infotext(basket_data))
end
