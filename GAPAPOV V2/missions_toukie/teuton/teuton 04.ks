Function Science {
  toggle ag1.
  wait 1.
  toggle ag2.
  wait 1.
}

lock steering to heading(90,90).
lock throttle to 1.
stage.
wait until stage:solidfuel = 0.
stage.
wait until altitude > 300000.
Science().
wait until 0=1.
