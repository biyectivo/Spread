spread_connect_xlsx("Test.xlsx", "db_game_data");
spread_define_table("tbl_items", "db_game_data", "Items", "b3:g8", [
	new Spread_ID("id"),
	new Spread_String("item", true, 3, 25),
	new Spread_Num("range", true, false, 0,,true),
	new Spread_Num("attack", false, false, 0,,true),
	new Spread_Num("power_attack", false, false, 0,, true),
	new Spread_Boolean("can_break", true)
]);
//spread_connect_xlsx("My Spreadsheet.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Database", "b2:g8");
//spread_connect_xlsx("spread_roguelite_5000_testdata.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "b2:g8");

var _keys = struct_get_names(global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"]);
for  (var _k=0, _n=array_length(_keys); _k<_n; _k++) {
	var _key = _keys[_k];
	var _cell = global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"][$ _key];
	show_debug_message($"{_key}: {_cell}");
}
spread_disconnect("db_game_data");

game_end();