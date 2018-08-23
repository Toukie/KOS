wait 1.
T_Stage["LaunchStage"]().
T_Stage["StageCheck"]().

T_GUI["StatusCheck"]().
local GivenParameterList is T_GUI["CompleteParameterGUI"]().
T_ReadOut["InitialReadOut"](10).

local CircParameter is T_GUI["CircGUI"]().
local InputList is list().

if CircParameter = "periapsis" {
  set InputList to list(time:seconds + eta:periapsis, 0, 0, 0).
} else {
  set InputList to list(time:seconds + eta:apoapsis, 0, 0, 0).
}

local NewScoreList is list().
local NewRestrictionList is T_HillUni["IndexFiveFolderder"]("realnormal_antinormal").
local FinalMan is T_HillUni["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
T_ManeuverExecute["ExecuteManeuver"](FinalMan).

T_GAPAPOV["GAPAPOV"](GivenParameterList).
clearguis().