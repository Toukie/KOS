// relay sat setup

TX_lib_dependencies["AllDepencies"](scriptpath()).

Function GetNorm {
  return vcrs(ship:velocity:orbit, - body:position):direction.
}


if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](1000000).
  TX_lib_man_exe["Circularization"]().
}

ag1 on.
lock steering to GetNorm().
stage.
unlock steering.

TX_lib_man_exe["ChangeApoapsis"](list(242057)).
local warpt is time:seconds + eta:periapsis.
warpto(warpt).
wait until time:seconds > warpt.
TX_lib_man_exe["ChangePeriapsis"](list(1000000)).
lock steering to GetNorm().
stage.
unlock steering.

TX_lib_man_exe["ChangeApoapsis"](list(242057)).
warpto(warpt).
wait until time:seconds > warpt.
TX_lib_man_exe["ChangePeriapsis"](list(1000000)).
lock steering to GetNorm().
stage.
unlock steering.
