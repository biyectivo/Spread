draw_text(10, 10, spread_prod_mode());
var _item = spread_get_item("2", "tbl_items");
draw_text(10, 50, string($"{_item.item} r={_item.range} atk={_item.attack} power_attack={_item.power_attack}"));