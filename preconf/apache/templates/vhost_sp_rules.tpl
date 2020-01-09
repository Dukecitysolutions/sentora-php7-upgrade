
#### vhost CUSTOM snuffleupagus rules - SAFE TO ADD ABOVE HERE

#### vhost Default snuffleupagus rules - DO NOT EDIT/DELETE BELOW
# Harden the `chmod` function
sp.disable_function.function("chmod").param("mode").value_r("^[0-9]{2}[67]$").allow();

# Prevent runtime modification of interesting things
sp.disable_function.function("ini_set").param("varname").value("memory_limit").allow();

# Ensure that certificates are properly verified
sp.disable_function.function("curl_setopt").param("value").value("1").allow();
sp.disable_function.function("curl_setopt").param("value").value("2").allow();
# `81` is SSL_VERIFYHOST and `64` SSL_VERIFYPEER
sp.disable_function.function("curl_setopt").param("option").value("64").allow().alias("Please don't turn CURLOPT_SSL_VERIFYCLIENT off."); #should be drop. SSL curl_opt issue CHECK
sp.disable_function.function("curl_setopt").param("option").value("81").allow().alias("Please don't turn CURLOPT_SSL_VERIFYHOST off."); #should be drop. SSL curl_opt issue CHECK

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

