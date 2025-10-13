# Baskets API Reference

## Basket object

A table with two fields, `description` and `items`. Represents all data inside a basket.

```lua
{
    description = "", -- User-defined basket description, default empty
    items = { -- List of items in the basket
        ItemStack(),
        ItemStack(),
        -- 30 more...
    },
}
```

## Obtain basket object

* `basket.get_basket_from_node(pos)`: Obtain a [basket object](#basket-object) from a basket node in the world.
  * `pos`: The node's coordinates. Has to be a `basket:basket`.
  * Returns the corrisponding basket object on success, `nil` if the node is not a basket or is not loaded.
* `basket.get_basket_from_item(itemstack)`: Obtain a basket object from a basket ItemStack.
  * `itemstack`: [ItemStack](https://github.com/luanti-org/luanti/blob/master/doc/lua_api.md#itemstack) of the basket
  * Return the corrisponding basket object on success, `nil` if the item is not a basket.

## Apply basket objects

* `basket.set_basket_node_data(pos, basket_data)`: Apply data inside a [basket object](#basket-object) onto a basket node.
  * `pos`: The basket node's coordinates. Has to be a `basket:basket`.
  * `basket_data`: Basket data to be applied.
* `basket.get_basket_itemstack(basket_data)`: Obtain a basket ItemStack corrisponding to the given basket data.
  * `basket_data`: Basket data to be applied.
  * Returns an ItemStack. It is a `basket:basket_craftitem` for empty baskets, and otherwise `basket:basket`.
