

{

global TX_lib_warp is lexicon(
  "WarpToPhaseAngle", WarpToPhaseAngle@,
  "WarpToEjectionAngle", WarpToEjectionAngle@
  ).
  local TXStopper is "[]".

Function WarpToPhaseAngle {

  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is sun.
  Parameter WarpOverride is 100000.

  local CurrentPhaseAngle is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetPlanet, StartingBody, ReferenceBody).
  local TargetPhaseAngle  is TX_lib_phase_angle["PhaseAngleCalculation"](TargetPlanet, StartingBody, ReferenceBody).

  TX_lib_other["WarpSetter"](75, WarpOverride).

  // maybe add modfied ish where if its after the goal it doesnt register
  until TX_lib_other["ish"](CurrentPhaseAngle, TargetPhaseAngle, ishyness) {
    set CurrentPhaseAngle to TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetPlanet, StartingBody, ReferenceBody).
    TX_lib_readout["PhaseAngleGUI"](CurrentPhaseAngle, TargetPhaseAngle).
  }

  TX_lib_other["WarpDecreaser"]().
  print CurrentPhaseAngle.
}


// if we are in a smaller orbit than our target we need to burn at x degrees from the
// prograde of the ship's planet, if we are in a bigger orbit than our target we need
// to burn at x degrees from the retrograde of the ship's planet.

Function WarpToEjectionAngle {

  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is Sun.

  local ResultList is TX_lib_phase_angle["EjectionAngleVelocityCalculation"](TargetPlanet, ReferenceBody).
  local EjectionAng is ResultList[0].
  HUDtext("Insertion burn " + ResultList, 5, 2, 30, white, true).

  local CurrentEjectionAngle is 1000. // nonsense value for now
  local lock PosToNegAngle to vcrs(vcrs(ship:velocity:orbit, body:position),ship:body:orbit:velocity:orbit).
  local lock NegToPosAngle to vcrs(ship:body:orbit:velocity:orbit, vcrs(ship:velocity:orbit, body:position)).

  print "ejection angle needed: " + EjectionAng.

  TX_lib_other["WarpSetter"](75).

  until TX_lib_other["Ish"](CurrentEjectionAngle, EjectionAng, Ishyness){

  if TargetPlanet:orbit:semimajoraxis > StartingBody:orbit:semimajoraxis {
    if vang(-body:position, PosToNegAngle) < vang(-body:position, NegToPosAngle) {
      set CurrentEjectionAngle to 360 - vang(-body:position , body:orbit:velocity:orbit).
    } else {
      set CurrentEjectionAngle to vang(-body:position , body:orbit:velocity:orbit).
    }
    EjectionAngleGUI(CurrentEjectionAngle, EjectionAng, "pro").
    print "Angle from prograde:   " + CurrentEjectionAngle at (1,4).
  }

  if TargetPlanet:orbit:semimajoraxis < StartingBody:orbit:semimajoraxis {
    if vang(-body:position, NegToPosAngle) < vang(-body:position, PosToNegAngle) {
      set CurrentEjectionAngle to 360 - vang(-body:position , -body:orbit:velocity:orbit).
    } else {
      set CurrentEjectionAngle to vang(-body:position , -body:orbit:velocity:orbit).
    }
    EjectionAngleGUI(CurrentEjectionAngle, EjectionAng, "retro").
    print "Angle from retrograde: " + CurrentEjectionAngle at (1,4).
  }
 }

 TX_lib_other["WarpDecreaser"]().
}
}
print "read lib_warp".
