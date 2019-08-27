global TX_lib_closest_approach is lexicon(
  "ClosestApproachFinder", ClosestApproachFinder@,
  "DistanceAtTime", DistanceAtTime@
).
local TXStopper is "[]".

Function ClosestApproachFinder {
  parameter TargetDestination.
  parameter FindTime is false.

  local ScoreManeuver is nextnode. // node should already exists (see the scoring function)

  local StartTime is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 90).
  local Endtime is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 270).

  local AllApproachLists is list().
  local DegreeStepper is 90.
  until DegreeStepper >= 270 {
    local ApproachTime is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, DegreeStepper).
    local ApproachDist is DistanceAtTime(TargetDestination, ApproachTime).
    local ApproachList is list(ApproachTime, ApproachDist).
    AllApproachLists:add(ApproachList).
    //log ApproachList to ("0:/ApLog").
    //log DegreeStepper to ("0:/ApLog").
  //  log "---" to ("0:/ApLog").
    set DegreeStepper to DegreeStepper + 1.8.
  }

  local ClosestApproach is AllApproachLists[0][1]. // just an initial step
  local BestList is AllApproachLists[0].

  for SomeList in AllApproachLists {
    if SomeList[1] < ClosestApproach {
      set ClosestApproach to SomeList[1].
      set BestList to SomeList.
    }
  }

  //log "Best: " to ("0:/ApLog").
  //log BestList to ("0:/ApLog").
  //log DegreeStepper to ("0:/ApLog").

  // finding which entry this was

  local CurrentIndex is AllApproachLists:indexof(BestList).

  local StartTime is 0. // temporary value
  if CurrentIndex = 0 {
    set StartTime to TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 88.2).
  } else {
    set StartTime to AllApproachLists[CurrentIndex-1][0].
  }

  local Endtime is 0.
  if CurrentIndex = AllApproachLists:length - 1 {
    set Endtime to TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, 271.8).
  } else {
    set Endtime to AllApproachLists[CurrentIndex+1][0].
  }


  local BestTime is TX_lib_hillclimb_main["MinGoldSection"](DistanceAtTime@:bind(list(TargetDestination)), StartTime, Endtime).
  local BestDistance is DistanceAtTime(list(TargetDestination), BestTime).

  print "Best distance: " + round(BestDistance/1000) + " km".
  HUDtext("Best distance: " + round(BestDistance/1000) + " km", 5, 2, 30, white, true).

  if FindTime = true {
    return BestTime.
  }

  return BestDistance.

  // take 100 points between TA of 90 and 270
  // score those points and pick the best one
  // goldensearch of one before best and one after best


}

Function DistanceAtTime {
  Parameter TargetDestination.
  Parameter T.

  if TargetDestination:istype("list") { // this is the case with ClosestApproachFinder() because it needs to pass a list for the main GS method
    set TargetDestination to TargetDestination[0].
  }

  return ((positionat(ship, T) - positionat(TargetDestination, T)):mag).
}

print "read lib_closest_approach".
