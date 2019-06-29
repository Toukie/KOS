TX_lib_dependencies["AllDepencies"](scriptpath()).
wait 1.
clearscreen.
  if ship:status = "prelaunch" {
    TX_lib_ascent["MainLaunch"](250000).
    TX_lib_man_exe["Circularization"]().
    TX_lib_stage["StageCheck"]().

    local TargetDestination is eve.
    set target to TargetDestination.
    local TargetPeriapsis is 200000.
    local TargetInclination is 0.

    TX_lib_transfer_planet["InterplanetaryTransfer"](TargetDestination, TargetPeriapsis, TargetInclination).
  }
  panels on.

  local BestNode is TX_lib_inclination["InclinationCorrection"](45, 100).
  add node(BestNode[0], BestNode[1], BestNode[2], BestNode[3]).
  wait 1.
  print nextnode:orbit:inclination.
  //TX_lib_man_exe["ExecuteManeuver"](BestNode).
  wait until false.

  local TargetDestination is eve.
  set target to TargetDestination.
  add node(time:seconds, 0, 0, 0).
  wait 0.
  local InterceptTime is TX_lib_closest_approach["ClosestApproachFinder"](TargetDestination, true).
  remove nextnode.
  deletepath(interceptlog).
  log InterceptTime to interceptlog.
