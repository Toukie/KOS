global TX_lib_precision_landing is lexicon(
  "GetLatETA", GetLatETA@,
  "ToTargetLatLng", ToTargetLatLng@
).

local TXStopper is "[]".

Function LatScore {
  parameter TargetLat.
  parameter TimeTill.

  local PredictedLat is body:geopositionof(positionat(ship, time:seconds + TimeTill)):lat.
  local LatPenalty is abs((TargetLat - PredictedLat)/TargetLat).
  return LatPenalty.
}

Function GetLatETA {
  parameter TargetLat.

  local ETAtoMaxLat is TX_lib_hillclimb_main["MinGoldSection"](LatScore@:bind(TargetLat), 0, ship:orbit:period).
  return ETAtoMaxLat.
}

Function LngDifference {
  parameter InputLng.
  parameter TargetLng.

  // check if lng is increasing or decreasing
  local lng1 is ship:geoposition:lng.
  wait 1.
  local lng2 is ship:geoposition:lng.
  local LngIncrease is true.
  local DeltaDeg is "?".

  // lng is positive
  if lng1 > 0 {
    if lng1 < lng2 {
      set LngIncrease to false.
    }
  } else {
    if lng1 > lng2 {
      set LngIncrease to false.
    }
  }

  if LngIncrease = true {
    if InputLng < TargetLng {
      set DeltaDeg to TargetLng - InputLng.
    } else {
      set DeltaDeg to 180 - InputLng + 180 + TargetLng.
    }
  } else {
    if InputLng > TargetLng {
      set DeltaDeg to InputLng - TargetLng.
    } else {
      set DeltaDeg to 180 + InputLng + 180 - TargetLng.
    }
  }

  print "Lng increasing " + LngIncrease.

  return DeltaDeg.
}

Function ToTargetLatLng {
  parameter TargetLat.
  parameter TargetLng.

  local TimeTill is GetLatETA(TargetLat).

  print "time till southern/northern most point " + TimeTill.

  local LngAtTime is body:geopositionof(positionat(ship, time:seconds + TimeTill)):lng.
  local OneDeg is body:rotationperiod/360.
  local DeltaDeg is LngDifference(LngAtTime, TargetLng).
  local IncreasedTime is DeltaDeg * OneDeg.

  print "current lng at S/N most point " + LngAtTime.
  print "target  lng " + round(TargetLng, 2).
  print "dlng " + DeltaDeg.
  print "one degree takes " + OneDeg.
  print "Extra time needed " + round(IncreasedTime).

  local CurPeriod is ship:orbit:period.
  //local TarPeriod is CurPeriod + IncreasedTime.
  local TarPeriod is IncreasedTime.
  print "target period " + TarPeriod.
  local TarSMA is (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).
  local StartAlt is ship:body:altitudeof(positionat(ship, time:seconds + TimeTill)).
  local DvNeeded is TX_lib_calculations["VisViva"](StartAlt, TarSMA).
  local ApproachNode is list(time:seconds + TimeTill, 0, 0, DvNeeded).
  local RealNode is node(ApproachNode[0], ApproachNode[1], ApproachNode[2], ApproachNode[3]).
  add RealNode.
  wait 0.

  local AcceptableNode is false.

  until AcceptableNode = true {
    if nextnode:orbit:periapsis < 1000 {
      remove nextnode.
      wait 0.
      local WarpTime is time:seconds + ship:orbit:period.
      warpto(WarpTime).
      wait until time:seconds > 0.99 * WarpTime.
      wait until kuniverse:timewarp:rate = 1.
      HUDtext("In need of extra orbit", 15, 2, 30, red, true).
      ToTargetLatLng(TargetLat, TargetLng).
      HUDtext("I ran", 15, 2, 30, red, true).
    } else if nextnode:orbit:hasnextpatch = true {
      remove nextnode.
      wait 0.
      local WarpTime is time:seconds + ship:orbit:period.
      warpto(WarpTime).
      wait until time:seconds > 0.99 * WarpTime.
      wait until kuniverse:timewarp:rate = 1.
      HUDtext("In need of extra orbit", 15, 2, 30, red, true).
      ToTargetLatLng(TargetLat, TargetLng).
      HUDtext("I ran", 15, 2, 30, red, true).
    } else {
      set AcceptableNode to true.
    }
  }

  if hasnode {
    remove nextnode.
    wait 0.
  }

  TX_lib_man_exe["ExecuteManeuver"](ApproachNode).
  print "burn done".
  print "current period: " + ship:orbit:period.
  print ship:geoposition.
  local LatETA is GetLatETA(TargetLat).
  local TimeTillLat is time:seconds + LatETA.
  warpto(TimeTillLat).
  until time:seconds > TimeTillLat {
    clearscreen.
    print ship:geoposition.
    wait 0.1.
  }
  print ship:geoposition.

}



print "read lib_precision_landing".
