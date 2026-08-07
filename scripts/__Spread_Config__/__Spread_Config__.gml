// Change these
#macro		SPREAD_DEV_MODE							true									// Enable for development mode (use the spreadsheets as source), disable for release mode (use the generated JSON files)
#macro		SPREAD_ALLOW_DEV_MODE_OUTSIDE_IDE		false									// Enable this to allow development mode while on a build
#macro		SPREAD_LOG_MESSAGE_LEVEL				SPREAD_MESSAGE_LEVEL.INFO				// Log level verbosity
#macro		SPREAD_JSON_BUNDLE_PATHS				"json/"									// Path for generated JSON files - use a relative path with default Gamemaker sandboxed mode, or use a full path (e.g. filename_path(GM_project_filename) + "datafiles/json/") if your sandbox is disabled
#macro		SPREAD_JSON_BUNDLE_EXTENSION			".dat"									// Extension for your JSON files