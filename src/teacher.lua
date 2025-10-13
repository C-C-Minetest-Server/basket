-- basket/src/teacher.lua
-- Teacher tutorials
-- Copyright (c) 2022, 2024-2025  1F616EMO
-- SPDX-LICENSE-IDENTIFIER: LGPL-2.1-OR-LATER

if not core.get_modpath("teacher_core") then
    return
end

local S = core.get_translator("basket")

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

basket.formspec = basket.formspec .. "button[6,0;1,1;teacher;?]"