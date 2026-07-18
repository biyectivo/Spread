
# Spread

**Spread** lets you keep game data in an XLSX workbook (e.g. from Excel) while developing, validate that data when GameMaker loads it, and use the result as normal GML structs. Then, when you build your project, you get rid of the XLSX file and use saved JSON files, seamlessly.

This gives game designers a friendly, familiar editing format such as a spreadsheet, that can be changed at will during development, but without making the shipped game parse spreadsheets at runtime.

The basic idea is simple:

1. Put your data in an XLSX worksheet.
2. Tell **Spread** what each column means and what specifications should it have.
3. Load a worksheet range as a table in Gamemaker.
4. **Spread** will make sure your data complies with your specifications.
5. Use your imported data for your game.
6. When you build your game, use the auto-generated JSON bundles instead of the original spreadsheet, _**without you having to rewrite code**_.

This guide uses an item database as the running example.


## Requirements

**Spread** works with Gamemaker LTS 2024+. It has officially been tested in Windows. Theoretically, it should also work in Linux and MacOS, since `libxprocess` supports it already, however you would need to build the appropriate regex wrapper executable in Linux/MacOS. Also this has not been tested!  Development mode currently does **not** support GX.games or other targets, and **Spread** does not support GMRT.

NOTE: While you cannot use **Spread** in development mode except for Windows (and possibly Linux and/or Mac as described), when you switch to production mode, you will be able to compile and run / build your game in whatever target platform you need. This is because, as described throughout this document, **Spread** converts all your defined data to JSON bundles that will automatically be read in that mode. So, for example, you can balance your game stats in Windows using **Spread**, then switch to Production (read below) and test/build for GX.Games, for example!

## What a Spread table looks like

Suppose the `Items` worksheet contains this range:

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| ID | Name | Description | Rarity | Price | Breakable |
| `itm_rusty_sword` | Rusty Sword | Better than nothing. | common | 20 | FALSE |
| `itm_fire_wand` | Fire Wand | Launches a small fireball. | rare | 125 | TRUE |
| `itm_lucky_coin` | Lucky Coin | Slightly improves luck. | epic | 300 | FALSE |

After connecting to your workbook, defining the table and loading it, **Spread** stores the table internally, as a struct of structs:

```gml
{
    itm_rusty_sword: {
        name: "Rusty Sword",
        description: "Better than nothing.",
        rarity: "common",
        price: 20,
        breakable: false
    },

    itm_fire_wand: {
        name: "Fire Wand",
        description: "Launches a small fireball.",
        rarity: "rare",
        price: 125,
        breakable: true
    },

	...
}
```

To access data from it, you use the `spread_get_*` functions.




## Add Spread to the project

Download the latest release (a YYMPS file) and import it into your Gamemaker project.

Spread uses several configuration macros from its options script, `__Spread_Config__`:

|Macro variable|Meaning|Default value
|-------------------------|---------------------------------------------------------------------|---|
| `SPREAD_DEV_MODE` | Whether you are using Development or Production mode:<br>*Development mode:* Spread reads and validates data from XLSX files.<br>*Production mode:* Spread skips XLSX processing and loads the previously generated JSON bundle.|`true`|
|`SPREAD_ALLOW_DEV_MODE_OUTSIDE_IDE`|Let Gamemaker automatically detect whether you're running outside the IDE (i.e. a build) and switches to Production mode, independently of the value of `SPREAD_DEV_MODE`.|`false`|
|`SPREAD_LOG_MESSAGE_LEVEL`|Sets the verbosity of the log messages, using the `SPREAD_MESSAGE_LEVEL` enum (you can choose between `SYSTEM`, `INFO`, `WARNING`, or `ERROR`.|`SPREAD_MESSAGE_LEVEL.INFO`|
|`SPREAD_JSON_BUNDLE_PATHS`|A **relative** directory path to where you want the auto-generated JSON files stored.|`json/`|
|`SPREAD_JSON_BUNDLE_EXTENSION`|The extension to be used for storing the auto-generated JSON files.|`.dat`

There are some other macro variables related to the regex utility used internally by the parser (see below) - try not to mess with these.



## Prepare the spreadsheet

Create a XLSX file with Excel, exporting it from Google Sheets etc., and place it in the local app data folder corresponding to your Gamemaker project (this is, for example, `C:\Users\<your username>\AppData\Local\Spread_Demo`). If for some reason you don't have that directory created, create it yourself.

For the most straightforward setup:

1. Put one item on each row.
2. Give every item a unique ID.
3. Avoid completely blank rows inside the selected range.
4. Save the workbook.

**Spread** can load either:

- A regular range address, such as `A1:F100`
- A workbook _named range_ such as `RangeItems`

A named range is usually easier to maintain because rows can be added without changing the GML range address, provided the name expands with the data.

### Row-oriented and column-oriented tables

Most databases are row-oriented:

```text
One row = one item
One column = one field
```

Use `_shape_is_rows = true`, which is also the default.

**Spread** can also read transposed data:

```text
One column = one item
One row = one field
```

For that format, use `_shape_is_rows = false`.



## Define the schema

A schema tells **Spread** how to interpret and validate each field. The schema array must follow the same order as the spreadsheet columns.

For the example range `A1:F4`:

```gml
var item_schema = [
    new Spread_ID("id"),
    new Spread_String("name", true),
    new Spread_String("description", true),
    new Spread_String(
        "rarity",
        true,
        0,
        infinity,
        ["common", "rare", "epic", "legendary"]
    ),
    new Spread_Num("price", true, true, 0),
    new Spread_Boolean("breakable", true, true)
];
```

There must be exactly one `Spread_ID` in every table schema.

### Available schema types

#### `Spread_ID`

Use it for the unique item identifier:

```gml
new Spread_ID("id")
```

IDs are always required and must be unique within the table.
NOTE: **Spread** does not currently handle multi-ID rows - just create a combined field in the XLSX that is unique to each row/column.

#### `Spread_String`

Use it for names, descriptions, categories, tags, asset names, and similar text values:

```gml
new Spread_String("name", true)
```

A more constrained example:

```gml
new Spread_String(
		"rarity",                 	// Field name
		true,                    	// Required
		3,                        	// Minimum length (default=0)
		12,                       	// Maximum length (default=infinity)
		["common", "rare", "epic"], // Allowed values array (default=[])
		[],                       	// Forbidden values array (default=[])
		"",                       	// Must contain (default="")
		"",                       	// Must not contain (default="")
		"",                       	// Must start with (default="")
		""                        	// Must end with (default="")
)
```

#### `Spread_Num`

Use it for integers, decimal values, modifiers, prices, levels, weights, probabilities, and spreadsheet dates:

```gml
new Spread_Num(
		"damage", 					// Field name
		true,						// Required
		false,						// Is integer? (default=false)
		0,							// Minimum value (default=-infinity)
		100,						// Maximum value (default=infinity)
		true, 						// Is minimum excluded from the range? (default=false)
		false,						// Is maximum exlcuded from the range? (default=false)
		_allowed_list=[], 			// Allowed values array (default=[])
		_forbidden_list=[],			// Forbidden values array (default=[])
		false						// Read a numeric XLSX serial number and treat it as a string date (default=false)
```


#### `Spread_Boolean`

Use strict mode when the worksheet contains actual boolean cells:

```gml
new Spread_Boolean("breakable", true, true)
```

Non-strict mode accepts configured truthy and falsy values:

```gml
new Spread_Boolean(
	    "can_explode",					// Field name
	    false,							// Required
	    false,							// Are only true and false allowed as valid values? (default=false)
	    ["yes", "YES"],					// List of allowed values for true
	    ["no", "NO"]					// List of allowed values for false
)
```


#### `Spread_FK`

Use a foreign key when a field must reference an ID from another Spread table:

```gml
new Spread_FK(
			"powerup_ID",				// Field name,
			false,						// Required
			"game_powerups"				// Table name
)
```

The referenced table **must already exist** when the foreign-key schema is created. Define tables in dependency order, e.g.:

```text
powerups → items
```

NOTE: Self-references are not supported in the current version.



## Connect to the workbook

Create the connection during initialization, preferably in a `Create` or `Room Start` event:

```gml
spread_connect_xlsx(
    "data/items.xlsx",
    "game_data"			
);
```

The arguments are:

```gml
spread_connect_xlsx(
    _filename,				// Spreadsheet filename
    _connection_name,		// Unique connection ID
   _force					// Whether to rebuild an existing connection
)
```

**Spread** will process the XLSX file and create temporary cache files with the data. These will be deleted when you disconnect.

When Gamemaker sandboxing (default) is enabled, use `%LOCALAPPDATA%\<Your Game Folder>` as the folder; if for some reason you have it disabled, use the full source path instead.

When **Spread** is in production mode, this call is automatically ignored without you needing to do anything else, so you don't have to disable or delete this call.



## Define and load the table

Once the connection exists, define the table, specifying the fields as an array of **Spread** schemas:

```gml
var item_schema = [
    new Spread_ID("id"),
    new Spread_String("name", true),
    new Spread_String("description", true),
    new Spread_String(
        "rarity",
        true,
        0,
        infinity,
        ["common", "rare", "epic", "legendary"]
    ),
    new Spread_Num("price", true, true, 0),
    new Spread_Boolean("breakable", true, true)
];

spread_define_table(
    "items",          	// Unique table ID
    "game_data",      	// The unique connection ID from which this table is defined
    "Items",          	// Worksheet name from your connected XLSX file
    "A1:F100",        	// Address or named range from your connected XLSX file
    item_schema,		// The defined schema
    1                   // 0-based index of the first row with values    
    // there are more optional parameters, these are explained later in the documentation
);
```

In this example, the selected range contains six columns, so the schema must contain exactly six entries.

When calling the table definition, **Spread** will parse and load into memory the worksheet data. The first time it does so, it might take a couple of seconds (especially if you have a big XLSX with thousands of rows / hundreds of columns). However, this will be readily available for table definitions that come after the first one and load data from the same worksheet.

After doing so, **Spread** will also validate your data against the Schema.



## Read data in the game

### Get one value

To get a single field from a specific ID in a particular table:

```gml
var price = spread_get(
    "itm_fire_wand",		// Item key
    "price",				// Field to get
    "items"					// Table ID
);
```

### Get the complete item struct

To get the complete set of fields for a particular item:

```gml
var item = spread_get_item(
	"itm_fire_wand", 		// Item key
	"items"					// Table
);

show_debug_message(item.name);
show_debug_message(item.price);
```

### Get the complete table

If you need to get the complete table:

```gml
var items = spread_get_table("items");
var fire_wand = items[$ "itm_fire_wand"];
```

Using the direct table struct is convenient when several values will be read together. Using the getter functions gives clearer errors when a table, key, or field is missing.

### Check whether an item exists

```gml
if (spread_exists("itm_lucky_coin", "items")) {
    var coin = spread_get_item("itm_lucky_coin", "items");
}
```

### Check whether a table exists

```gml
if (spread_table_exists("items")) {
    show_debug_message("The item database is ready.");
}
```

### Get item IDs

To get the list of all IDs from a particular table:

```gml
var all_item_ids = spread_get_item_keys("items");
```

Or if you need to just get the ones that meet a specific condition, use a callback:

```gml
var expensive_item_ids = spread_get_item_keys(
    "items",
    function(_item) {
        return _item.price >= 100;
    }
);
```

The function returns keys, not item structs. Use each key with `spread_get_item()` or the complete table.

```gml
for (var i = 0; i < array_length(expensive_item_ids); i++) {
    var id = expensive_item_ids[i];
    var item = spread_get_item(id, "items");
    show_debug_message($"{item.name}: {item.price}");
}
```



## Add cross-field validation

Individual schemas validate one field at a time. Use an *item validation function* for rules involving several fields.

For example, require `maximum_level` to be at least `minimum_level`:

```gml
var validate_item = function(_item) {
    return _item.maximum_level >= _item.minimum_level;
};
```

Pass it to `spread_define_table()`:

```gml
spread_define_table(
    "items",
    "game_data",
    "Items",
    "RangeItems",
    item_schema,
    1,
    ,
    ,
    validate_item
);
```

The callback receives the item fields, excluding the `Spread_ID` value.



## Add whole-table validation

A table validation function can check rules across multiple records.

For example, require at least one legendary item:

```gml
var validate_item_table = function(_table) {
    var keys = struct_get_names(_table);

    for (var i = 0; i < array_length(keys); i++) {
        var item = _table[$ keys[i]];

        if (item.rarity == "legendary") {
            return true;
        }
    }

    return false;
};
```

And you pass it to the definition function like before.  You can also provide both validation callbacks:

```gml
spread_define_table(
    "items",
    "game_data",
    "Items",
    "RangeItems",
    item_schema,
    1,
    ,
    ,
    validate_item,
    validate_item_table
);
```



## Decide how validation failures should behave

By default, `_error_on_schema_validation_fail` is `true`. This means a schema, item, or table validation failure throws an exception. This is the recommended behavior while building and balancing the game.  Set it to `false` only when you deliberately want loading to continue - in this case, **Spread** will only print an error message to the log:

```gml
spread_define_table(
    "items",
    "game_data",
    "Items",
    "RangeItems",
    item_schema,
    1,
    ,
    false
);
```

Invalid non-ID fields are then stored as `undefined`, and processing continues. 

NOTE: Invalid IDs cannot be safely ignored because they are used as struct keys, so if an ID is invalid **Spread** will throw an exception regardless of the value of `_error_on_schema_validation_fail`.



## Reload data while developing

You can modify your XLSX spreadsheet while your game is running; after editing and saving the XLSX file, reload a previously defined table at runtime with:

```gml
spread_reload_table("items");
```

The table remembers its original connection, sheet, range, schema, offset, orientation, and validation callbacks.

It is recommended to wrap reloads in `try...catch`, so a spreadsheet mistake does not crash the complete test session and the previously loaded data is preserved, like so:

```gml
try {
    spread_reload_table("items");
    show_debug_message("Items reloaded successfully.");
}
catch (exception) {
    show_debug_message("Could not reload items:");
    show_debug_message(exception);
}
```


## Inspect table metadata

Spread records useful information whenever a table is loaded:

```gml
var metadata = spread_get_table_metadata("items");

show_debug_message(metadata.source_type);
show_debug_message(metadata.source_sheet);
show_debug_message(metadata.source_range);
show_debug_message(metadata.table_loaded);
show_debug_message(metadata.table_sha1);
```

In development, `source_type` is `"XLSX"`. In production, it is `"JSON"`.

Metadata is useful for debug screens, reload tools, diagnostics, and confirming which bundle is active.



## Development and production workflow

Whenever a table is successfully defined from XLSX with `spread_define_table`, **Spread** automatically generates a JSON bundle using the configured bundle folder and extension. These are automatically generated on your `%LOCALAPPDATA%\<your project>` folder, where your XLSX sits.

Note that previously generated JSON files are automatically overwritten by **Spread** when re-loading tables.

When you switch to a build, **you need to copy those JSON files to your `datafiles` folder**, and ensure they are exported to your target platform (they will be by default, but double-check by clicking on them and inspecting them). Since your XLSX sits in your `%LOCALAPPDATA%` storage, it will not be included in the build by Gamemaker. Actually, when you are already in Production mode, you can even move/rename/delete your XLSX file, since your game won't read from it anymore!

NOTE: Although technically possible, do not store your XLSX files in your `datafiles` folder, always use `%LOCALAPPDATA%` to prevent accidentally bundling them into the project.

Again, you **do not** need to modify your code (i.e. change/delete/comment/disable your `spread_connect_xlsx`, `spread_disconnect` etc. function calls. This is handled automatically by **Spread**.


## Disconnect when the workbook is no longer needed

To remove an XLSX connection and its temporary cache:

```gml
spread_disconnect("game_data");
```

Loaded **Spread** tables remain separate from the connection. In production mode there is no XLSX connection to close, so the call is automatically skipped.

## Your spreadsheet file can contain almost anything

You are not limited to having only black and white numbers in your XLSX! Actually having your data there means you can have things like cell comments, tables, charts, complex formulas, macros etc., and have only the resulting data you need loaded into Gamemaker. This allows you to tune/tweak directly in your spreadsheet, do things like compare scenarios, formulate things, do statistics, etc., and use that same file to load your data, convert automatically to JSON and use it seamlessly in production.

## Technical stuff

**Spread** relies on `libxprocess` from `high on tantor` (Samuel Venable) to launch and interact with console commands at runtime (download this fabulous extension [here](https://samuel-venable.itch.io/gamemaker-extension-collection)).

Also, it uses a [regular expression wrapper program written in Rust](https://github.com/biyectivo/regex_wrapper) (converted with Devin from Python-like syntax - because I like Python) to read stdin or filename strings and match/extract/substitute data from the files.

These two things are bundled into the YYMPS and are automatically added when you import **Spread** - make sure to keep them in your project!

## Complete example

You can clone [a complete game example](https://github.com/biyectivo/Spread-Demo) I created to showcase what you can do with **Spread**. It's a very simple Bloons-like tower defense stub. Note that you will also need to download the XLSX spreadsheet listed in the repo README, and place it into `%LOCALAPPDATA\Spread_Demo`, so you can open it and experiment with it.

## Function list

|Function|Purpose|
|-|-|
|spread_connect_xlsx|Connects to an XLSX file|
|spread_define_table|Defines a table by reading data from your connected XLSX file|
|spread_disconnect|Closes a connection with an XLSX file|
|spread_exists|Checks if an item exists in a defined **Spread** table|
|spread_get|Gets a specific field from a particular item present in a **Spread** table|
|spread_get_item|Gets a complete item (with all its fields) from a particular **Spread** table|
|spread_get_item_keys|Gets all IDs from a particular **Spread** table|
|spread_get_table|Gets a complete **Spread** table|
|spread_get_table_metadata|Gets the metadata from a particular **Spread** table|
|spread_prod_mode|Returns if **Spread** is running in production mode|
|spread_reload_table|Reloads a previously-defined **Spread** table from the connected XLSX|
|spread_table_exists|Checks if a **Spread** table has been defined

## Current limitations and design decisions

- **Spread** reads _cached formula results_; it does not calculate spreadsheet formulas itself.  Keep this in mind, especially if your XLSX is in manual calculation mode. You can read this directly from Gamemaker from the table metadata.
- You need to save your workbook in XLSX formato with any compatible spreadsheet. This is the Office Open XML Spreadsheet (.xlsx) format, supported by Microsoft Excel 2007+, Microsoft 365, Google Sheets, LibreOffice, and other standards-compliant spreadsheet applications.
- Shared-formula metadata is not fully reconstructed at this time.
- Inline strings are not currently supported by the worksheet parser.
- **Spread** currently only supports rectangular ranges at this time - no disjoint ranges.

## FAQ

|Question|Answer|
|-|-|
|Does **Spread** support connecting to Google Sheets?|Not directly at this time. However you can work with Google Sheets and then export your sheet as an XLSX (File → Download → Microsoft Excel) and work with that.|
|Does **Spread** support macro-enabled files (XLSM)?|Yes.|
|If I want my game to run/build in GX.Games, can I use **Spread**?|You cannot use **Spread** in development mode with GX.Games at the moment; however, you can develop in Windows, then switch to production mode and run your game in GX.Games without issue (make sure to copy your JSON bundle to your `datafiles` as described earlier)|
|How performant is **Spread**?|For the majority of uses it will be near-instant. Both `libxprocess` and the regex wrapper built in Rust are very fast. If your XLSX has thousands of rows, the first time you load a table it will take a couple of seconds to do it completely. Note that this is done synchronously, not asynchronously.`

## License

MIT, free and open source (FOSS).
Note that `libxprocess` is also FOSS.