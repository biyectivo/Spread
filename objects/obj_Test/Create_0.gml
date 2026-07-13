spread_connect_xlsx("Test.xlsx", "db_game_data");
spread_define_table("tbl_items", "db_game_data", "Items", "b3:i8", [
	new Spread_ID("id"),
	new Spread_String("item", true, 3, 25),
	new Spread_Num("range", true, false, 0,,true),
	new Spread_Num("attack", false, false, 0,,true),
	new Spread_Num("power_attack", false, false, 0,, true),
	new Spread_Boolean("can_break", true),
	new Spread_String("power_upgrade", false),
	new Spread_Num("date", true, true,,,,,,,true)
]
);


//spread_define_table("tbl_items", "db_game_data", "Monsters", "c5:f8", [
//	new Spread_ID("monster"),
//	new Spread_Num("hp",true,true),
//	new Spread_Num("speed",true),
//	new Spread_Num("range",false)
//],1,false,,function(_item) {
//	return _item.speed + (_item.range ?? 0) <= 4;
//});

//spread_define_table("tbl_powers", "db_game_data", "Items", "powers", [
//	new Spread_ID("power_id"),
//	new Spread_String("power_description", true,, 20),
//	new Spread_Num("value", true, true, 0, 50, true),
//], 1);


//spread_define_table("tbl_items", "db_game_data", "Items", "b3:h8", [
//	new Spread_ID("id"),
//	new Spread_String("item", true, 3, 25),
//	new Spread_Num("range", true, false, 0,,true),
//	new Spread_Num("attack", false, false, 0,,true),
//	new Spread_Num("power_attack", false, false, 0,, true),
//	new Spread_Boolean("can_break", true),
//	new Spread_FK("power", false, "tbl_powers")
//]);


//spread_connect_xlsx("Test.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "b3:g8", [
//	new Spread_ID("id"),
//	new Spread_String("item", true, 3, 25),
//	new Spread_Num("range", true, false, 0,,true),
//	new Spread_Num("attack", false, false, 0,,true),
//	new Spread_Num("power_attack", false, false, 0,, true),
//	new Spread_Boolean("can_break", true)
//]);

//spread_connect_xlsx("Test.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "my_named", [
	
//	new Spread_ID("item"),
//	new Spread_Num("range", true, false, 0,,true),
//	new Spread_Num("attack", false, false, 0,,true),
//	new Spread_Num("power_attack", false, false, 0,, true),
//]);


//spread_connect_xlsx("spread_roguelite_5000_testdata.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "a1:e50", [
//	new Spread_ID("item_id"),
//	new Spread_String("item_name", true, 5),
//	new Spread_String("item_description", true, 10),
//	new Spread_String("rarity", true,,,["Common", "Uncommon", "Rare", "Epic", "Legendary", "Cursed", "Relic"]),
//	new Spread_Num("price", true, false, 0,,true)
//], 1,,true);


//spread_define_table("tbl_items", "db_game_data", "Items", "a2:e5001", [
//	new Spread_ID("item_id"),
//	new Spread_String("item_name", true, 5),
//	new Spread_String("item_description", true, 10),
//	new Spread_String("rarity", true,,,["Common", "Uncommon", "Rare", "Epic", "Legendary", "Cursed", "Relic"]),
//	new Spread_Num("price", true, false, 0,,true)
//],,,,,function(_table) {
//	var _sum = 0;
//	var _cnt = 0;
//	var _keys = struct_get_names(_table);
//	for (var _i=0, _n=array_length(_keys); _i<_n; _i++) {
//		var _key = _keys[_i];
//		_sum += _table[$ _key].price;
//		_cnt++;
//	}
//	return abs(_sum/_cnt - 41) < 1;
//});



//spread_define_table("tbl_items", "db_game_data", "Items", "aj2:ao5001", [	
//	new Spread_String("tuning_warning", true),
//	new Spread_String("txt_formula", true),
//	new Spread_String("upgrade", false,,10,,,,,"upg"),
//	new Spread_Num("last_tuned_at", true, true, 0),
//	new Spread_Boolean("min_max_valid", true, true),
//	new Spread_ID("item_id"),
//]);


var _keys = spread_get_item_keys("tbl_items");
for  (var _k=0, _n=array_length(_keys); _k<_n; _k++) {
	var _key = _keys[_k];
	var _cell = spread_get_item(_key, "tbl_items");
	show_debug_message($"{_key}: {_cell}");
}

show_debug_message(spread_get_table_metadata("tbl_items"));

//show_debug_message(spread_get_item_keys("tbl_items"));

spread_disconnect("db_game_data");

//show_debug_message(json_stringify(global.Spread, true))

game_end();