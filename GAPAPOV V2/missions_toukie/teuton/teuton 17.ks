TX_lib_dependencies["AllDepencies"](scriptpath()).

clearscreen.
local lantar is 109.8 + 90.
until TX_lib_calculations["ish"](ship:orbit:lan , lantar, 5) {

  print "   " + round(ship:orbit:lan, 2) + "   " at(1,5).
  print "   " + lantar + "   " at(1,6).
  wait 0.5.
}
set warp to 0.
wait until kuniverse:timewarp:rate = 1.

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](200000, 90).
  TX_lib_man_exe["Circularization"]().

  TX_lib_man_exe["ChangeApoapsis"](list(11580179)).
  TX_lib_man_exe["Circularization"]().
  TX_lib_man_exe["ChangeApoapsis"](list(12032410)).
}
