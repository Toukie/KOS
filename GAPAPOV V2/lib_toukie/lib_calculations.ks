global TX_lib_calculations is lexicon(
  "VisViva", VisViva@,
  "Ish", Ish@,
  "ClosestApproachFinder", ClosestApproachFinder@,
  "DistanceAtTime", DistanceAtTime@,
  "CurrentDv", CurrentDv@,
  "BestReturnPe", BestReturnPe@,
  "GetSign", GetSign@
).
local TXStopper is "[]".

Function VisViva {
  Parameter StartAlt.
  // At which altitude do you want to start the burn
  Parameter TargetSMA.
  // What's the SMA at the end?

  local GM is body:mu.
  local StartAlt is StartAlt + body:radius.
  // StartAlt parameter does NOT include the body's radius (so it's added here)
  local VeloStart is SQRT(GM * ((2/StartAlt) - (1/ship:orbit:semimajoraxis)) ).
  local VeloEnd is SQRT(GM * ((2/StartAlt) - (1/TargetSMA)) ).
  local DvNeeded is VeloEnd-VeloStart.

  return DvNeeded.
}

Function Ish {
  Parameter a.
  Parameter b.
  Parameter ishyness.

  return a - ishyness < b and a + ishyness > b.
}

Function ClosestApproachFinder {
  parameter TargetDestination.

  local ScoreManeuver is nextnode. // node should already exists (see the scoring function)

  local StartTime is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 90).
  local Endtime is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 270).


  local BestTime is TX_lib_hillclimb_main["MinGoldSection"](DistanceAtTime@:bind(list(TargetDestination)), StartTime, Endtime).
  local BestDistance is DistanceAtTime(list(TargetDestination), BestTime).
  print "Best distance: " + round(BestDistance/1000) + " km".

  return round(BestDistance,2).

}

Function DistanceAtTime {
  Parameter TargetDestination.
  Parameter T.

  if TargetDestination:istype("list") { // this is the case with ClosestApproachFinder() because it needs to pass a list for the main GS method
    set TargetDestination to TargetDestination[0].
  }

  return ((positionat(ship, T) - positionat(TargetDestination, T)):mag).
}

Function CurrentDv {

  local eIsp is 0.
  local MyEngs is list().
  list engines in MyEngs.
  for Eng in MyEngs {
    local EngMaxThrust is max(0.001, eng:maxthrust).
    set eIsp to eISP + ((EngMaxThrust/maxthrust)*eng:isp).
  }
  local Ve is eIsp * 9.80665.
  local CurDv is Ve * ln(ship:mass / ship:drymass).

  return CurDv.
}

Function BestReturnPe {
  if ship:body:body:atm:exists {
    return ship:body:body:atm:height + 10000.
  } else {
    return 100000.
  }
}

Function GetSign {
  parameter Input.

  if Input * -1 < 0 {
    return 1.
  } else if Input * -1 > 0 {
    return -1.
  } else {
    return 0.
  }
}


print "read lib_calculations".
