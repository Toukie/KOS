global TX_lib_warp is lexicon(
  "MaxAcceptableWarp", MaxAcceptableWarp@,
  "WarpToPhaseAngle",  WarpToPhaseAngle@,
  "WarpToEjectionAngle", WarpToEjectionAngle@
  ).
local TXStopper is "[]".

Function MaxAcceptableWarp {
  parameter TargetObject is ship.
  parameter MaxSpeed is (7/18). // degrees of true anomaly per tick... just a little better than 1/3

  local dTA is 0.
  local WarpRate is 0.
  local LexStepper is 1.

  local WarpLex is lexicon(
    0,	1,
    1,	5,
    2,	10,
    3,	50,
    4,	100,
    5,	1000,
    6,	10000,
    7, 	100000
  ).


  local OldSpeed is 0.
  local NewSpeed is 0.

  until false {
    set OldSpeed to kuniverse:timewarp:warp.
    set kuniverse:timewarp:warp to LexStepper.
    wait 0.
    if kuniverse:timewarp:rate = WarpLex[LexStepper-1] {  // if warp stays the same break
      set LexStepper to LexStepper - 1.
      break.
    }
    wait until kuniverse:timewarp:rate = WarpLex[LexStepper]. // make sure its going at warping speed
    local TA1 is TargetObject:orbit:trueanomaly.
    wait 0.
    local TA2 is TargetObject:orbit:trueanomaly.
    set dTA to abs(TA1-TA2).
    set NewSpeed to kuniverse:timewarp:warp.

    if dta < MaxSpeed {  // can be any number but this is decent
      if OldSpeed = NewSpeed {
        break.
      }
      set LexStepper to LexStepper + 1.
    } else {
      set LexStepper to LexStepper - 1.
      break.
    }
  }

  // if max warp available isnt high enough cut it off

  set kuniverse:timewarp:warp to 0.
  return LexStepper. // max warp number
}

Function WarpToPhaseAngle {
  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is ship:body:body.

  local CurrentPhaseAngle is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetPlanet, StartingBody, ReferenceBody).
  local TargetPhaseAngle  is TX_lib_phase_angle["PhaseAngleCalculation"](TargetPlanet, StartingBody, ReferenceBody).

  local MaxWarp is MaxAcceptableWarp(StartingBody).
  set kuniverse:timewarp:warp to MaxWarp.
  clearscreen.

  // maybe add modfied ish where if its after the goal it doesnt register
  print "TargetPhaseAngle:  " + TargetPhaseAngle at(0,9).
  until TX_lib_calculations["ish"](CurrentPhaseAngle, TargetPhaseAngle, ishyness) {
    set CurrentPhaseAngle to TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetPlanet, StartingBody, ReferenceBody).
    wait 0.
    print "                            " at(0,10).
    print "CurrentPhaseAngle: " + round(CurrentPhaseAngle, 3) at (0,10).
  }

  set kuniverse:timewarp:warp to 0.
  wait until kuniverse:timewarp:rate = 1.

}

Function WarpToEjectionAngle {

  Parameter TargetPlanet.
  Parameter Ishyness.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is ship:body:body.

  local ResultList is TX_lib_phase_angle["EjectionAngleVelocityCalculation"](TargetPlanet, ReferenceBody).
  local EjectionAng is ResultList[0].
  HUDtext("Insertion burn " + ResultList, 5, 2, 30, white, true).

  local CurrentEjectionAngle is 1000. // nonsense value for now
  local lock PosToNegAngle to vcrs(vcrs(ship:velocity:orbit, body:position),ship:body:orbit:velocity:orbit).
  local lock NegToPosAngle to vcrs(ship:body:orbit:velocity:orbit, vcrs(ship:velocity:orbit, body:position)).

  print "ejection angle needed: " + EjectionAng.

  set warp to MaxAcceptableWarp().

  until TX_lib_calculations["Ish"](CurrentEjectionAngle, EjectionAng, Ishyness){

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

 set warp to 0.
 wait until kuniverse:timewarp:rate = 1.
}

print "read lib_warp".
