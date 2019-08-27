TX_lib_dependencies["AllDepencies"](scriptpath()).
clearscreen.
core:doaction("Close Terminal", true).

local ParameterList is TX_lib_gui["CompleteParameterGUI"]().
TX_lib_apollo["APOLLO"](ParameterList).
