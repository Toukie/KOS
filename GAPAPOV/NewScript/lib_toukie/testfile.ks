Function WarpTest {
  Parameter NumberOfChecks.

  local WarpSpeed is ship:orbit:period/NumberOfChecks.
  print round(WarpSpeed).

  if WarpSpeed > 1000 {
    if WarpSpeed < 9000 {
      set WarpSpeed to 1000.
    }

    if WarpSpeed < 90000 {
      set WarpSpeed to 10000.
    }
  }

  set kuniverse:timewarp:rate to WarpSpeed.
}

Function WarpDecreaser {
  set kuniverse:timewarp:warp to 0.
  until kuniverse:timewarp:rate = 0 {
    wait 0.5 * kuniverse:timewarp:rate.
  }
}

print "up to some'tn".
WarpTest(20).
wait 1800.
WarpDecreaser().
