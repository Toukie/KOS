wait 1.
T_Stage["LaunchStage"]().
T_Stage["StageCheck"]().

local GivenParameterList is T_GUI["CompleteParameterGUI"]().
T_GAPAPOV["GAPAPOV"](GivenParameterList).
