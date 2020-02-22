
#### vhost Default snuffleupagus rules - DO NOT EDIT/DELETE BELOW
# Harden the `chmod` function
#sp.disable_function.function("chmod").param("mode").value_r("^[0-9]{2}[67]$").allow(); ###### check

# Prevent various `mail`-related vulnerabilities
sp.disable_function.function("mail").param("additional_parameters").value_r("\\-").drop();

# Prevent `system`-related injections
sp.disable_function.function("system").param("command").value_r("[$|;&`\\n\\(\\)\\\\]").drop();
sp.disable_function.function("shell_exec").param("command").value_r("[$|;&`\\n\\(\\)\\\\]").drop();
sp.disable_function.function("exec").param("command").value_r("[$|;&`\\n\\(\\)\\\\]").drop();
sp.disable_function.function("proc_open").param("command").value_r("[$|;&`\\n\\(\\)\\\\]").drop();

# Prevent runtime modification of interesting things
sp.disable_function.function("ini_set").param("varname").value("assert.active").drop();
sp.disable_function.function("ini_set").param("varname").value("zend.assertions").drop();
sp.disable_function.function("ini_set").param("varname").value("memory_limit").drop(); ###### 128MB default .If you have issues change vhost .htaccess/php.ini memory_limit instead
sp.disable_function.function("ini_set").param("varname").value("include_path").drop();
sp.disable_function.function("ini_set").param("varname").value("open_basedir").drop();

# Detect some backdoors via environnement recon
sp.disable_function.function("ini_get").param("varname").value("allow_url_fopen").drop();
sp.disable_function.function("ini_get").param("varname").value("open_basedir").drop();
# sp.disable_function.function("ini_get").param("varname").value_r("suhosin").drop(); ###### CHECK causes Suhosin check issues with apps
sp.disable_function.function("function_exists").param("function_name").value("eval").drop();
sp.disable_function.function("function_exists").param("function_name").value("exec").drop();
sp.disable_function.function("function_exists").param("function_name").value("system").drop();
sp.disable_function.function("function_exists").param("function_name").value("shell_exec").drop();
sp.disable_function.function("function_exists").param("function_name").value("proc_open").drop();
sp.disable_function.function("function_exists").param("function_name").value("passthru").drop();
sp.disable_function.function("is_callable").param("var").value("eval").drop();
sp.disable_function.function("is_callable").param("var").value("exec").drop();
sp.disable_function.function("is_callable").param("var").value("system").drop();
sp.disable_function.function("is_callable").param("var").value("shell_exec").drop();
sp.disable_function.function("is_callable").param("var").value("proc_open").drop();
sp.disable_function.function("is_callable").param("var").value("passthru").drop();

# Functions - Disabled for system security - WARNING DO NOT CHANGE. USE panel to set vhost override.  :-)
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

