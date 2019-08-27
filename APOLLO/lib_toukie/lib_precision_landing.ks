global TX_lib_precision_landing is lexicon(
  "GetLatETA", GetLatETA@,
  "ToTargetLatLng", ToTargetLatLng@,
  "FullLanding", FullLanding@
).

local TXStopper is "[]".

Function LatScore {
  parameter TargetLat.
  parameter TimeTill.

  if TargetLat < 1 {
    set TargetLat to 1.
  }

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

  local DeltaDeg is "".

  if InputLng > TargetLng {
    set DeltaDeg to InputLng - TargetLng.
  } else {
    set DeltaDeg to 180 + InputLng + 180 - TargetLng.
  }

  return DeltaDeg.
}

Function ToTargetLatLng {
  parameter TargetLat.
  parameter TargetLng.

  for n in allnodes { remove n.}
  local TimeTill is GetLatETA(TargetLat).
  local orbit_count is 0.
  local AcceptableNode is false.
  local ApproachNode is list().

  until AcceptableNode {
    for n in allnodes { remove n.}
    wait 0.
    print "time till southern/northern most point " + TimeTill.

    local node_time is time:seconds + TimeTill + orbit_count*ship:orbit:period.
    local delta_time is TimeTill + orbit_count*ship:orbit:period.

    local LngAtTime is body:geopositionof(positionat(ship, node_time)):lng.
    local Deg_Rate_body is 360/body:rotationperiod.
    set LngAtTime to LngAtTime - Deg_Rate_body*delta_time.
    local check_lng is false.

    until check_lng {
      if LngAtTime < -180 {
        set LngAtTime to LngAtTime + 360.
      } else if LngAtTime > 180 {
        set LngAtTime to LngAtTime - 360.
      } else {
        set check_lng to true.
      }
    }

    local DeltaDeg is LngDifference(LngAtTime, TargetLng).
    local IncreasedTime is DeltaDeg/Deg_Rate_body.

    print "current lng at S/N most point " + LngAtTime.
    print "target  lng " + round(TargetLng, 2).
    print "dlng " + DeltaDeg.
    print "one degree takes " + 1/Deg_Rate_body.
    print "Extra time needed " + round(IncreasedTime).

    local CurPeriod is ship:orbit:period.
    //local TarPeriod is CurPeriod + IncreasedTime.
    local TarPeriod is IncreasedTime.
    print "target period " + TarPeriod.
    local TarSMA is (((TarPeriod^2)*ship:body:mu)/(4*constant:pi^2))^(1/3).
    local StartAlt is ship:body:altitudeof(positionat(ship, time:seconds + TimeTill)).
    local DvNeeded is TX_lib_calculations["VisViva"](StartAlt, TarSMA).
    set ApproachNode to list(node_time, 0, 0, DvNeeded).
    local RealNode is node(ApproachNode[0], ApproachNode[1], ApproachNode[2], ApproachNode[3]).
    add RealNode.
    wait 0.

    local check_peri is nextnode:orbit:periapsis > 10000.
    local check_apo is nextnode:orbit:apoapsis > 0 AND nextnode:orbit:apoapsis < ship:body:soiradius - ship:body:radius AND nextnode:orbit:hasnextpatch = false.
    if check_peri AND check_apo {
      set AcceptableNode to true.
    } else {
      set orbit_count to orbit_count + 1.
    }
    wait 1.
  }

  for n in allnodes { remove n.}
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

Function FullLanding {
  parameter TargetLat.
  parameter TargetLng.

  ToTargetLatLng(TargetLat, TargetLng).
  TX_lib_man_exe["Decircularization"](0, -10000, true).
  TX_lib_landing["KillHorizontalVel"](15).
  TX_lib_landing["SuicideBurn"]().
}


print "read lib_precision_landing".
