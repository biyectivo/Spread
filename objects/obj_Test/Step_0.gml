if (keyboard_check_pressed(vk_space)) {
	//spread_reload_table("tbl_items");
	try {
		spread_reload_table("tbl_items");
	}
	catch (_exception) {
		show_debug_message("Could not load fresh data, maintaining the old one...");
	}
}