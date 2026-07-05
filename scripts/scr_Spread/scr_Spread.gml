///@feather ignore all

#macro		SPREAD_VERSION						"0.1"

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

global.Spread = {};

global.Spread[$ "config"] = {

	mode: SPREAD_MODE.DEV,
	maintain_data_on_invalid_refresh: true,
	live_reload_enabled: true,
	log_message_level: SPREAD_MESSAGE_LEVEL.INFO,

};

global.Spread.connections = {};
global.Spread.tables = {};



global.Spread[$ "config"] = {

	mode: global.Spread.enums.SPREAD_MODE.get("DEV"),
	strict: true,
	cache_enabled: true,
	live_reload_enabled: true,
	log_message_level: global.Spread.enums.SPREAD_MESSAGE_LEVEL.get("INFO"),

};

global.Spread.connections = {};
global.Spread.tables = {};


#region Functions

	#region Helpers
		
		
		/**
		 * @desc	logs a message with specified level to the Gamemaker log, if its level is greater than or equal to the current set message level in Spread's options
		 * @param	{string}		_message_text									the text to send
		 * @param	{real}		[_message_level]=SPREAD_MESSAGE_LEVEL.SYSTEM		the message level
		 * @param	{bool}		[_exception_on_error]=true							if the level is ERROR, and this is true, it will throw an exception instead of just logging the message.
		 */
		function __spread_log(_message_text, _message_level=SPREAD_MESSAGE_LEVEL.SYSTEM, _exception_on_error=true) {
			if (_message_level >= global.Spread.config.log_message_level) {
				var _message = string($"{SPREAD_LOG_PREFIX} {_message_level}: {_message_text}");
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
				if (!file_exists(_input_json_filename))	__spread_log(string($"__spread_regex_json: File does not exist, {_input_json_filename}"), "ERROR");
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

#endregion