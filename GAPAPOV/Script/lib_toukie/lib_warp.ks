Function GetAllowedTimeWarp {
  if ship:orbit:periapsis > 2500000 {
    return 7.
  } else if ship:orbit:periapsis > 480000 {
    return 6.
  } else if ship:orbit:period > 20000 and ship:orbit:periapsis > 240000 {
    return 5.
  } else if ship:orbit:period > 4000 and ship:orbit:periapsis > 120000 {
    return 4.
  } else {
    return 3.
  }
}

Function WarpToPhaseAngle {

  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is sun.
  Parameter SlowWarp is false.

  set CurrentPhaseAngle to CurrentPhaseAngleFinder(TargetPlanet, StartingBody, ReferenceBody, true).
  set TargetPhaseAngle  to PhaseAngleCalculation(TargetPlanet, StartingBody, ReferenceBody, true).
  print TargetPhaseAngle at(1,6).

  if SlowWarp = true {
    set kuniverse:timewarp:warp to (GetAllowedTimeWarp()-1).
    set ishyness to ishyness+2.
  } else {
    set kuniverse:timewarp:warp to 10.
  }
  until ish(CurrentPhaseAngle, TargetPhaseAngle, ishyness) {
    set CurrentPhaseAngle to CurrentPhaseAngleFinder(TargetPlanet, StartingBody, ReferenceBody, true).
    print CurrentPhaseAngle at (1,5).
  }

  local WarpNumber  is 2.
  until WarpNumber = 8 {
    local CurrentWarp is kuniverse:timewarp:warp.
    set kuniverse:timewarp:warp to (CurrentWarp - WarpNumber).
    wait 5.
    set WarpNumber to WarpNumber + 1.
    if CurrentWarp = 0 {
      set WarpNumber to 8.
    }
  }
  wait 5.
  set kuniverse:timewarp:warp to 0.
  print CurrentPhaseAngle.
}


// if we are in a smaller orbit than our target we need to burn at x degrees from the
// prograde of the ship's planet, if we are in a bigger orbit than our target we need
// to burn at x degrees from the retrograde of the ship's planet.

Function WarpToEjectionAngle {

  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.

  EjectionAngleVelocityCalculation(TargetPlanet).

  set CurrentEjectionAngle to 1000. // nonsense value for now
  lock PosToNegAngle to vcrs(vcrs(ship:velocity:orbit, body:position),ship:body:orbit:velocity:orbit).
  lock NegToPosAngle to vcrs(ship:body:orbit:velocity:orbit, vcrs(ship:velocity:orbit, body:position)).

  print "ejection angle needed: " + EjectionAng.

  set kuniverse:timewarp:warp to (GetAllowedTimeWarp()-1).

  until ISH(CurrentEjectionAngle, EjectionAng, Ishyness){

  if TargetPlanet:orbit:semimajoraxis > StartingBody:orbit:semimajoraxis {
    if vang(-body:position, PosToNegAngle) < vang(-body:position, NegToPosAngle) {
      set CurrentEjectionAngle to 360 - vang(-body:position , body:orbit:velocity:orbit).
    } else {
      set CurrentEjectionAngle to vang(-body:position , body:orbit:velocity:orbit).
    }
    print "Angle from prograde:   " + CurrentEjectionAngle at (1,4).
  }

  if TargetPlanet:orbit:semimajoraxis < StartingBody:orbit:semimajoraxis {
    if vang(-body:position, NegToPosAngle) < vang(-body:position, PosToNegAngle) {
      set CurrentEjectionAngle to 360 - vang(-body:position , -body:orbit:velocity:orbit).
    } else {
      set CurrentEjectionAngle to vang(-body:position , -body:orbit:velocity:orbit).
    }
    print "Angle from retrograde: " + CurrentEjectionAngle at (1,4).
  }
}

 set warpnumber to 2.
 until warpnumber = 8 {
   set kuniverse:timewarp:warp to (GetAllowedTimeWarp() - warpnumber).
   wait 5.
   set WarpNumber to WarpNumber + 1.
 }
 wait 5.
 set kuniverse:timewarp:warp to 0.
}

print "read lib_warp".
