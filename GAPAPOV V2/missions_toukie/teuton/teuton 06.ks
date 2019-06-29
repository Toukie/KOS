lock steering to heading(90,90).
lock throttle to 1.
stage.

wait until ship:solidfuel = 0.
stage.

wait until ship:apoapsis > 90000.
lock throttle to 0.
until ship:altitude > 70000 {
  if ship:apoapsis < 71000 {
    until ship:apoapsis > 90000 {
      lock throttle to 1.
    }
  }
  lock throttle to 0.
  wait 1.
}
toggle ag1.

wait until altitude < 20000.
stage.
