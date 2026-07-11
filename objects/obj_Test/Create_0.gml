//spread_connect_xlsx("Test.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "b3:g8", [
//	new Spread_ID("id"),
//	new Spread_String("item", true, 3, 25),
//	new Spread_Num("range", true, false, 0,,true),
//	new Spread_Num("attack", false, false, 0,,true),
//	new Spread_Num("power_attack", false, false, 0,, true),
//	new Spread_Boolean("can_break", true)
//]);
//spread_connect_xlsx("My Spreadsheet.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Database", "b2:g8");
//spread_connect_xlsx("spread_roguelite_5000_testdata.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "a1:e5000", [
//	new Spread_ID("item_id"),
//	new Spread_String("item_name", true, 5),
//	new Spread_String("item_description", true, 10),
//	new Spread_String("rarity", true,,,["Common", "Uncommon", "Rare", "Epic", "Legendary", "Cursed", "Relic"]),
//	new Spread_Num("price", true, false, 0,,true)

//], 1,,true);
spread_connect_xlsx("Test.xlsx", "db_game_data");
spread_define_table("tbl_items", "db_game_data", "Monsters", "D5 : F8", [
	new Spread_ID("monster"),
	new Spread_Num("hp", true),
	new Spread_Num("spd", true),
	new Spread_Num("range", false, false, -1, 1)
	
],,false);

var _keys = struct_get_names(global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"]);
for  (var _k=0, _n=array_length(_keys); _k<_n; _k++) {
	var _key = _keys[_k];
	var _cell = global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"][$ _key];
	show_debug_message($"{_key}: {_cell}");
}

spread_disconnect("db_game_data");

game_end();