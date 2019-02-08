set_global_assignment -entity "TemperatureSensor" -library "lib_TemperatureSensor" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "TemperatureSensor" -library "lib_TemperatureSensor" -name IP_TOOL_VERSION "16.1"
set_global_assignment -entity "TemperatureSensor" -library "lib_TemperatureSensor" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_TemperatureSensor" -name SPD_FILE [file join $::quartus(sip_path) "../TemperatureSensor.spd"]
set_global_assignment -library "lib_TemperatureSensor" -name MISC_FILE [file join $::quartus(sip_path) "../../TemperatureSensor.qsys"]

set_global_assignment -library "lib_TemperatureSensor" -name MISC_FILE [file join $::quartus(sip_path) "TemperatureSensor.vhd"]
set_global_assignment -library "lib_TemperatureSensor" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_temp_sense.v"]
