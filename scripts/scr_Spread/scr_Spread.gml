///@feather ignore all

#macro		SPREAD_VERSION						"0.1"

#region Enums 

	enum SPREAD_MODE {
		DEV,
		PROD
	}

	enum SPREAD_MESSAGE_LEVEL {
		INFO,
		WARNING,
		ERROR,
		SYSTEM
	}
	
#endregion


#region Init and default config

	global.Spread = {};

	global.Spread.connections = {};
	global.Spread.tables = {};
	
	
	global.Spread[$ "config"] = {

		mode: SPREAD_MODE.DEV,
		maintain_data_on_invalid_refresh: true,
		live_reload_enabled: true,
		log_message_level: SPREAD_MESSAGE_LEVEL.INFO,

	};


#endregion

#region String version of enums

	global.Spread.enums = {};
	global.Spread.enums[$ "SPREAD_MODE"] = ["DEV", "PROD"];
	global.Spread.enums[$ "MESSAGE_LEVEL"] = ["INFO", "WARNING", "ERROR", "SYSTEM"];

#endregion


#region Functions

	#region Helpers
		
		
		/**
		 * @desc	logs a message with specified level to the Gamemaker log, if its level is greater than or equal to the current set message level in Spread's options
		 * @param	{string}		_message_text									the text to send
		 * @param	{real}		[_message_level]=SPREAD_MESSAGE_LEVEL.SYSTEM		the message level
		 * @param	{bool}		[_exception_on_error]=true							if the level is ERROR, and this is true, it will throw an exception instead of just logging the message.
		 */
		function __spread_log(_message_text, _message_level=SPREAD_MESSAGE_LEVEL.SYSTEM, _exception_on_error=true) {
			var _callstack = debug_get_callstack();
			var _calling_from = string_replace_all( array_length(_callstack) == 1 ? _callstack[0] : _callstack[1] , "gml_Script", "");
			_calling_from = string_split(_calling_from, ":")[0];
			if (_message_level >= global.Spread.config.log_message_level) {
				var _message = string($"{SPREAD_LOG_PREFIX} ({global.Spread.enums[$ "MESSAGE_LEVEL"][_message_level]}):  {_calling_from}: 	{_message_text}");
				if (_message_level == SPREAD_MESSAGE_LEVEL.ERROR && _exception_on_error) {
					throw(_message);
				}
				else {
					show_debug_message(_message);
				}
			}
		}
		
		#region Regex management
		
			/**
			 * @desc	escapes a string to prepare for execution with libxprocess and the regex.exe program, substituting double quotes with single quotes and replacing spaces with the set space char in options
			 * @param	{string}		_string						the string to escape
			 * @param	{string}		[_spaces_escape_char]="¬"	the escape char to use for spaces
			 * @returns {string}		the escaped string
			 */
			function __spread_regex_escape(_string, _spaces_escape_char=SPREAD_REGEX_SPACE_ESCAPE_CHAR) {			
				var _output = string_replace_all(string_replace_all(_string, chr(34), "'"), " ", _spaces_escape_char);
				return _output;
			}
		
			/**
			 * @desc	finds all matches (or all capture groups) of the regex within the string, similar to Python's findall. Automatically escapes the string
			 * @param	{string}	_string			the string to parse
			 * @param	{string}	_regex			a string with the regex to use
			 * @param	{string}	[_flags]=""		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {string}	a stringified JSON array with the matches
			 */
			function __spread_regex_findall(_string, _regex, _flags="") {
				var _escaped_contents = __spread_regex_escape(_string);
			
				var _process = string($"regex findall {_escaped_contents} \"{_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
				return _output;
			}
		
			
			/**
			 * @desc	gets the index of the first match of the provided regex within the string. Automatically escapes the string
			 * @param	{string}	_string			the string to parse
			 * @param	{string}	_regex			a string with the regex to use
			 * @param	{string}	[_flags]=""		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {real}	returns the 0-based index if there's a match or -1 if not
			 */
			function __spread_regex_search(_string, _regex, _flags="") {
				var _escaped_contents = __spread_regex_escape(_string);
			
				var _process = string($"regex search {_escaped_contents} \"{_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = real(string_replace_all(string_replace_all(_output, "\n", ""), "\r", ""));
				return _output;
			}
		
			/**
			 * @desc	gets the index of the first match of the provided regex within the string. Automatically escapes the string
			 * @param	{string}	_string						the string to parse
			 * @param	{string}	_source_regex				a string with the source regex to use
			 * @param	{string}	_replacement_regex			a string with the replacement regex to use
			 * @param	{string}	[_flags]=""		optional string of flags to use when processing the regex (i=ignore-case, m=multiline, s=. matches newline, x=ignore whitespaces and comments, a=ascii, u=unicode)
			 * @returns {string}	the replaced string, or a stringified JSON array of replaced strings
			 */
			function __spread_regex_sub(_string, _source_regex, _replacement_regex, _flags="") {
				var _escaped_contents = _string;
			
				var _process = string($"regex sub \"{_escaped_contents}\" \"{_source_regex}\" \"{_replacement_regex}\" {_flags}");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
				return _output;
			}
		
			
			/**
			 * @desc	executes a series of regex operations defined in an input JSON file and optionally outputs the result to another JSON file
			 * @param	{string}	_input_json_filename			the input JSON with the definition of the regexes. The JSON must be an array with one or more structs, with the following keys:
			 *														"instruction":	<one of the following: search|findall|split|sub>,
			 *														"string":		<the target string. mutually exclusive with string_file>,
			 *														"string_file":	<a filename to take the string from. mutually exclusive with string>,
			 *														"pattern":		<the regex to use>
			 *														"replacement":	<the replacement regex to use (only for instruction=sub)>
			 *														"flags":		<optional string of flags to use>			 
			 * @param	{string}	[_json_output_filename]=""		optional filename to store the result into
			 * @returns {string}	a stringified JSON array of the results
			 */
			function __spread_regex_json(_input_json_filename, _json_output_filename="") {
				if (!file_exists(_input_json_filename))	__spread_log(string($"__spread_regex_json: File does not exist, {_input_json_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
				var _process = string($"regex --json \"{_input_json_filename}\" \"{_json_output_filename}\"");
			
				var _pid = ProcessExecute(_process);
				var _output = ExecutedProcessReadFromStandardOutput(_pid);
			
				FreeExecutedProcessStandardOutput(_pid);
				FreeExecutedProcessStandardInput(_pid);
			
				if (_json_output_filename == "") {
					_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "");
					return _output;
				}
				else {
					return _output;
				}
			}
		
		#endregion
	
	#endregion

	#region API
	
		#region XLSX
	
			/**
			 * @desc	Establishes a connection to an XLSX file
			 * @param	{string}	_filename				the filename. If Gamemaker is running sandboxed, the path relative to the datafiles/ folder; if not, the full path to the file
			 * @param	{string}	_connection_name		a unique identifer to name the connection (e.g. "db_items", etc.)
			 * @param	{bool}		[_force]=false			whether to conect again even if a cached connection exists
			 * @returns {bool}		whether the connection was succcessful
			 */
			function spread_connect_xlsx(_filename, _connection_name, _force=false) {
				if (struct_exists(global.Spread.connections, _connection_name))		__spread_log(string($"Connection already exists, {_connection_name}, type {global.Spread.connections[$ _connection_name].connection_type}, pointing to {global.Spread.connections[$ _connection_name].connection_source}"), SPREAD_MESSAGE_LEVEL.ERROR);
				if (!file_exists(_filename))	__spread_log(string($"File does not exist, {_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
			
			
				// Get file SHA1
				var _buffer = buffer_create(1, buffer_grow, 1);
				_buffer = buffer_load(_filename);
				var _sha1 = buffer_sha1(_buffer, 0, buffer_get_size(_buffer));
				buffer_delete(_buffer);
			
				// Check if file has changed
				if (SPREAD_CACHE_VERSIONS) {
					var _folder = string($"{_filename}_{_sha1}/");
			
					if (directory_exists(_folder) && !_force)	{
						__spread_log(string($"File {_filename} has not changed since last processing, and force was not specified. Skipping file update."),  SPREAD_MESSAGE_LEVEL.INFO);
						exit;
					}
			
					if (_force)	__spread_log(string($"Forced update of file {_filename} has been specified, regardless of whether file was changed. File processing will proceed."),  SPREAD_MESSAGE_LEVEL.INFO);
				}
				else { // force has no effect
					var _folder = string($"{_filename}/");	
					if (directory_exists(_folder)) directory_destroy(_folder);				
				}
			
				// Unzip the XLSX
				zip_unzip(_filename, _folder);
			
				if (!directory_exists(_folder))		__spread_log(string($"Could not process contents of XLSX spreadsheet, {_filename}"),  SPREAD_MESSAGE_LEVEL.ERROR);
			
				global.Spread.connections[$ _connection_name] = {
					connection_type: "xlsx",
					connection_source: _filename,
					connection_cache_folder: _folder,
					source_sha1: _sha1,
					connection_established: date_datetime_string(date_current_datetime()),
					title: undefined,
					creator: undefined,
					last_modified_by: undefined,
					date_created: undefined,
					date_modified: undefined,
					subject: undefined,
					description: undefined,
					application: undefined,
					application_version: undefined,
					calculation_mode: undefined,
					sheets: {},
					tables: {},
				};
				
				
				
				#region Load workbook metadata
			
					var _t = get_timer();
			
					// Perform extractions and subs
					var _json = [					
						{
							"instruction": "findall", // title
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dc:title[^>]*>([^<]*)</dc:title>"
						},
						{
							"instruction": "findall", // creator
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dc:creator[^>]*>([^<]*)</dc:creator>"
						},
						{
							"instruction": "findall", // last modified by
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<cp:lastModifiedBy[^>]*>([^<]*)</cp:lastModifiedBy>"
						},
						{
							"instruction": "findall", // date created
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dcterms:created[^>]*>([^<]*)</dcterms:created>"
						},
						{
							"instruction": "findall", // date modified
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dcterms:modified[^>]*>([^<]*)</dcterms:modified>"
						},
						{
							"instruction": "findall", // subject
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dc:subject[^>]*>([^<]*)</dc:subject>"
						},
						{
							"instruction": "findall", // description
							"string_file": game_save_id+_folder+"/docProps/core.xml",
							"pattern": "<dc:description[^>]*>([^<]*)</dc:description>"
						},	
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, game_save_id+"__spread_json_input.json");
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(game_save_id+"__spread_json_input.json", game_save_id+"__spread_json_output.json");
			
					// Read result from file
					if (!file_exists(game_save_id+"__spread_json_output.json"))		__spread_log("Error while parsing workbook metadata", SPREAD_MESSAGE_LEVEL.ERROR);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(game_save_id+"__spread_json_output.json");
					var  _metadata = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
			
					// Assign metadata
					if (array_length(_metadata[0]) > 0)		global.Spread.connections[$ _connection_name].title = _metadata[0][0];
					if (array_length(_metadata[1]) > 0)		global.Spread.connections[$ _connection_name].creator = _metadata[1][0];
					if (array_length(_metadata[2]) > 0)		global.Spread.connections[$ _connection_name].last_modified_by = _metadata[2][0];
					if (array_length(_metadata[3]) > 0)		global.Spread.connections[$ _connection_name].date_created = _metadata[3][0];
					if (array_length(_metadata[4]) > 0)		global.Spread.connections[$ _connection_name].date_modified = _metadata[4][0];
					if (array_length(_metadata[5]) > 0)		global.Spread.connections[$ _connection_name].subject = _metadata[5][0];
					if (array_length(_metadata[6]) > 0)		global.Spread.connections[$ _connection_name].description = _metadata[6][0];
			
					__spread_log(string($"Parsed workbook metadata in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
				
				#endregion
		
		
				#region Load spreadsheet program metadata
			
					var _t = get_timer();
			
			
					// Perform extractions and subs
					var _json = [					
						{
							"instruction": "findall", // application
							"string_file": game_save_id+_folder+"/docProps/app.xml",
							"pattern": "<Application[^>]*>([^<]*)</Application>"
						},
						{
							"instruction": "findall", // creator
							"string_file": game_save_id+_folder+"/docProps/app.xml",
							"pattern": "<AppVersion[^>]*>([^<]*)</AppVersion>"
						},
					];
					var _json_regex = json_stringify(_json);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					buffer_write(_buffer, buffer_text, _json_regex);
					buffer_save(_buffer, game_save_id+"__spread_json_input.json");
					buffer_delete(_buffer);
			
					var _output = __spread_regex_json(game_save_id+"__spread_json_input.json", game_save_id+"__spread_json_output.json");
			
					// Read result from file
					if (!file_exists(game_save_id+"__spread_json_output.json"))		__spread_log("error while parsing app metadata", SPREAD_MESSAGE_LEVEL.ERROR);
			
					var _buffer = buffer_create(1, buffer_grow, 1);
					_buffer = buffer_load(game_save_id+"__spread_json_output.json");
					var  _metadata = json_parse(buffer_read(_buffer, buffer_text));
					buffer_delete(_buffer);
			
					// Assign metadata
					if (array_length(_metadata[0]) > 0)		global.Spread.connections[$ _connection_name].application = _metadata[0][0];
					if (array_length(_metadata[1]) > 0)		global.Spread.connections[$ _connection_name].application_version = _metadata[1][0];
				
					__spread_log(string($"Parsed app metadata in {(get_timer()-_t)/1000000} seconds"), SPREAD_MESSAGE_LEVEL.INFO);
				
				#endregion
				
				
				if (file_exists(game_save_id+"__spread_json_input.json"))	file_delete(game_save_id+"__spread_json_input.json");
				if (file_exists(game_save_id+"__spread_json_output.json"))	file_delete(game_save_id+"__spread_json_output.json");
			
				__spread_log($"Connection named {_connection_name} successfully established to XLSX file {_filename}", SPREAD_MESSAGE_LEVEL.INFO);
				show_debug_message(global.Spread.connections[$ _connection_name]);
			
				return true;
			}
			
			
			/**
			 * @desc	Disconnects from an active Spread connection
			 * @param	{string}	_connection_name	The unique ID of the connection
			 */
			function spread_disconnect(_connection_name) {
				if (!struct_exists(global.Spread.connections, _connection_name))		__spread_log(string($"Connection {_connection_name} does not exist"), "ERROR");
				var _conn = global.Spread.connections[$ _connection_name];
				if (_conn.connection_type == "xlsx") {
					if (directory_exists(_conn.connection_cache_folder)) directory_destroy(_conn.connection_cache_folder);
				}
				
				__spread_log($"Disconnected from connection {_connection_name} (source file: {_conn.connection_source})", SPREAD_MESSAGE_LEVEL.INFO);
			}
	
		#endregion	

	#endregion

#endregion