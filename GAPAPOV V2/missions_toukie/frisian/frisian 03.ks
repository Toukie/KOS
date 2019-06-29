// going to the mun for real (intercept)

TX_lib_dependencies["AllDepencies"](scriptpath()).

local RunMode is 2.

if RunMode = 0 {
if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](250000).
  TX_lib_man_exe["Circularization"]().
}

clearscreen.
TX_lib_transfer_moon["MoonTransfer"](Mun, 45000, 0).
TX_lib_man_exe["Circularization"](periapsis).
ag1 on.
}

if RunMode = 1 {
  //TX_lib_man_exe["ExecuteManeuver"](list(time:seconds+300, 0, 0, 240)).
  //warpto(time:seconds + eta:transition + 10).

  TX_lib_man_exe["Circularization"](periapsis).
  TX_lib_man_exe["ChangeApoapsis"](list(90000)).
  TX_lib_man_exe["Circularization"](periapsis).
}

if RunMode = 2 {
  lock steering to retrograde.
  lock throttle to 1.
  wait until ship:periapsis < 30000.
  lock throttle to 0.
  wait until altitude < 15000.
  stage.
  unlock steering.
}
