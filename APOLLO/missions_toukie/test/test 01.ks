TX_lib_dependencies["AllDepencies"](scriptpath()).
// loads up all depencies

clearscreen.

local ParameterList is TX_lib_gui["CompleteParameterGUI"]().
// collects target destination parameters

TX_lib_apollo["APOLLO"](ParameterList).
// uses destination info to do the right things...
