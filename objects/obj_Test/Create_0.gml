var _process = string("regex");
			
var _pid = ProcessExecute(_process);
var _output = ExecutedProcessReadFromStandardOutput(_pid);
if (_output = string_replace_all(string_replace_all(_output, "\n", ""), "\r", "") != "") {
	show_debug_message($"{_output}");
}
			
FreeExecutedProcessStandardOutput(_pid);
FreeExecutedProcessStandardInput(_pid);
			
