//spread_connect_xlsx("Test.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "b3:g8", [
//	new Spread_ID("id"),
//	new Spread_String("item", true, 3, 25),
//	new Spread_Num("range", true, false, 0,,true),
//	new Spread_Num("attack", false, false, 0,,true),
//	new Spread_Num("power_attack", false, false, 0,, true),
//	new Spread_Boolean("can_break", true)
//],,,,function(_i) {
//	return _i.range <= _i.attack;
//},
//function(_table) {
//	var _sum = 0;
//	var _keys = struct_get_names(_table);
//	for (var _i=0, _n=array_length(_keys); _i<_n; _i++) {
//		var _key = _keys[_i];
//		_sum += _table[$ _key].range;
//	}
//	return _sum == 12;
//}
//);


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


spread_connect_xlsx("spread_roguelite_5000_testdata.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "a1:e50", [
//	new Spread_ID("item_id"),
//	new Spread_String("item_name", true, 5),
//	new Spread_String("item_description", true, 10),
//	new Spread_String("rarity", true,,,["Common", "Uncommon", "Rare", "Epic", "Legendary", "Cursed", "Relic"]),
//	new Spread_Num("price", true, false, 0,,true)
//], 1,,true);


spread_define_table("tbl_items", "db_game_data", "Items", "a2:e5001", [
	new Spread_ID("item_id"),
	new Spread_String("item_name", true, 5),
	new Spread_String("item_description", true, 10),
	new Spread_String("rarity", true,,,["Common", "Uncommon", "Rare", "Epic", "Legendary", "Cursed", "Relic"]),
	new Spread_Num("price", true, false, 0,,true)
],,,,,function(_table) {
	var _sum = 0;
	var _cnt = 0;
	var _keys = struct_get_names(_table);
	for (var _i=0, _n=array_length(_keys); _i<_n; _i++) {
		var _key = _keys[_i];
		_sum += _table[$ _key].price;
		_cnt++;
	}
	return abs(_sum/_cnt - 41) < 1;
});


var _keys = struct_get_names(global.Spread.tables[$ "tbl_items"]);
for  (var _k=0, _n=array_length(_keys); _k<_n; _k++) {
	var _key = _keys[_k];
	var _cell = global.Spread.tables[$ "tbl_items"][$ _key];
	show_debug_message($"{_key}: {_cell}");
}

//show_debug_message(spread_get_item_keys("tbl_items"));

spread_disconnect("db_game_data");

//show_debug_message(json_stringify(global.Spread, true))

game_end();