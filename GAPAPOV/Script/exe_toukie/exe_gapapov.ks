global TX_exe_gapapov is lexicon (
  "TXGetter", TXGetter@
).

Function TXGetter {
  local TXStopper is "[]".
}

TX_lib_stage["StageCheck"]().

//TX_lib_gui["StatusCheck"]().

local GivenParameterList is TX_lib_gui["CompleteParameterGUI"]().
TX_lib_readout["InitialReadOut"](10).

TX_lib_gapapov_main["GAPAPOV"](GivenParameterList).
clearguis().

wait 5.
HUDtext("Script complete", 5, 2, 30, red, true).
wait 0.5.
HUDtext("Script complete", 5, 2, 30, rgb(1, 0.647, 0), true).
wait 0.5.
HUDtext("Script complete", 5, 2, 30, yellow, true).
wait 0.5.
HUDtext("Script complete", 5, 2, 30, green, true).
wait 0.5.
HUDtext("Script complete", 5, 2, 30, blue, true).
wait 0.5.
HUDtext("Script complete", 5, 2, 30, purple, true).
