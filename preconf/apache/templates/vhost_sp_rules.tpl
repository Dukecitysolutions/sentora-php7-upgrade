
#### vhost CUSTOM snuffleupagus rules - SAFE TO ADD ABOVE HERE

#### vhost Default snuffleupagus rules - DO NOT EDIT/DELETE BELOW
# Harden the `chmod` function
sp.disable_function.function("chmod").param("mode").value_r("^[0-9]{2}[67]$").allow();

# Prevent runtime modification of interesting things
sp.disable_function.function("ini_set").param("varname").value("memory_limit").allow();

sp.disable_function.function("passthru").drop();
sp.disable_function.function("show_source").drop();
sp.disable_function.function("shell_exec").drop();
sp.disable_function.function("system").drop();
sp.disable_function.function("pcntl_exec").drop();
sp.disable_function.function("popen").drop();
sp.disable_function.function("pclose").drop();
sp.disable_function.function("proc_open").drop();
sp.disable_function.function("proc_nice").drop();
sp.disable_function.function("proc_terminate").drop();
sp.disable_function.function("proc_get_status").drop();
sp.disable_function.function("proc_close").drop();
sp.disable_function.function("leak").drop();
sp.disable_function.function("apache_child_terminate").drop();
sp.disable_function.function("posix_kill").drop();
sp.disable_function.function("posix_mkfifo").drop();
sp.disable_function.function("posix_setpgid").drop();
sp.disable_function.function("posix_setsid").drop();
sp.disable_function.function("posix_setuid").drop();
sp.disable_function.function("escapeshellcmd").drop();
sp.disable_function.function("escapeshellarg").drop();
sp.disable_function.function("exec").drop();
#### vhost Default snuffleupagus rules - DO NOT EDIT/DELETE ABOVE

