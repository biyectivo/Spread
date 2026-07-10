spread_connect_xlsx("Test.xlsx", "db_game_data");
spread_define_table("tbl_items", "db_game_data", "Items", "b2:g8");
//spread_connect_xlsx("My Spreadsheet.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Database", "b2:g8");
//spread_connect_xlsx("spread_roguelite_5000_testdata.xlsx", "db_game_data");
//spread_define_table("tbl_items", "db_game_data", "Items", "b2:g8");

var _keys = struct_get_names(global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"]);
for  (var _k=0, _n=array_length(_keys); _k<_n; _k++) {
	var _key = _keys[_k];
	var _cell = global.Spread.connections[$ "db_game_data"].tables[$ "tbl_items"][$ _key];
	var _formula = struct_exists(_cell, "formula") ? _cell.formula : "[no formula]";
	show_debug_message($"{_key}: {_cell.value} <-- {_formula}");
}

spread_disconnect("db_game_data");

game_end();