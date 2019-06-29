TX_lib_dependencies["AllDepencies"](scriptpath()).
stage.
local TargetDestination is vessel("rendtarget").
set target to TargetDestination.

TX_lib_rendezvous["FullRendezvous"](TargetDestination).
