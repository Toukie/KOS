// focused on getting kerbin surface science for new parts to go to the mun

TX_lib_dependencies["AllDepencies"](scriptpath()).

if ship:status = "prelaunch" {
  TX_lib_ascent["MainLaunch"](220000, 200).
  // 220000, 90 north pole
  // 140000, 160 desert
}

wait until altitude > 71000. // going up
wait until altitude < 70500. // going down
lock steering to retrograde.
lock throttle to 1.
wait until ship:velocity:surface:mag < 500.
lock throttle to 0.
stage.
wait 1.
stage.
unlock steering.

wait until ship:status <> "flying".
wait 2.
ag1 on. // science stuff
