///
/// INTERPLANETARY
///

Function InsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.

  WarpToPhaseAngle(TargetDestination, 1).
  WarpToEjectionAngle(TargetDestination, 1).

  local NewList is list(time:seconds + 300, 0, 0, InsertionBurnDv).

  local NewScoreList is list(TargetDestination, TargetPeriapsis).

  local NewRestrictionList is list(
    "none",
    "none",
    "none",
    "none",
    "none"
    ).

  local FinalMan is HillClimbLex["ResultFinder"](NewList, "Interplanetary", NewScoreList, NewRestrictionList).
  DvCalc(FinalMan).
  TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
  PerformBurn(EndDv, StartT).
}

Function ExitSOI {
  parameter TargetDestination.

  set SOIChange to time:seconds + eta:transition - 5.
  warpto(SOIChange).
  wait until time:seconds > SOIChange + 10.
  if ship:orbit:hasnextpatch = false  {
    return true.
  } else if ship:orbit:hasnextpatch = true and ship:orbit:nextpatch:body = TargetDestination {
    return false.
  } else {
    return true.
  }
}

Function CorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.

  local NewList is list(time:seconds + 300, 0, 0, 0).

  local NewScoreList is list(TargetDestination, TargetPeriapsis).

  local NewRestrictionList is list(
    "none",
    "none",
    "none",
    "none",
    "none"
    ).

  local FinalMan is HillClimbLex["ResultFinder"](NewList, "Interplanetary", NewScoreList, NewRestrictionList).
  DvCalc(FinalMan).
  TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
  PerformBurn(EndDv, StartT).
}

Function FinalCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local NewList is list(time:seconds + 300, 0, 0, 0).

  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).

  local NewRestrictionList is list(
    "prograde_retrograde",
    "prograde_retrograde",
    "prograde_retrograde",
    "prograde_retrograde",
    "prograde_retrograde"
    ).

  local FinalMan is HillClimbLex["ResultFinder"](NewList, "FinalCorrection", NewScoreList, NewRestrictionList).
  DvCalc(FinalMan).
  TimeTillManeuverBurn(FinalManeuver:eta, DvNeeded).
  PerformBurn(EndDv, StartT).
}

///
/// MOONS
///

Function MoonInsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local CombinedSMA is (TargetDestination:orbit:semimajoraxis + ship:altitude + ship:body:radius)/2.
  local RoughDv is VisViva(ship:altitude, CombinedSMA, true).

  local NewList is list(time:seconds + 30, 0, 0, RoughDv).
  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is list(
    "retrograde_realnormal_antinormal_radialin_radialout",
    "none",
    "none",
    "none",
    "none"
    ).
  // ^^^ first value retrograde
  local FinalMan is HillClimbLex["ResultFinder"](NewList, "MoonTransfer", NewScoreList, NewRestrictionList).
  ExecuteManeuver(FinalMan).
}

Function MoonCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local NewList is list(time:seconds + 180, 0, 0, 0).
  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is list(
    "none",
    "none",
    "none",
    "none",
    "none"
    ).

  local FinalMan is HillClimbLex["ResultFinder"](NewList, "MoonTransfer", NewScoreList, NewRestrictionList).
  ExecuteManeuver(FinalMan).
}

Function MoonPostEncounterBurn {
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  print "post correcting".

  InclinationMatcher2(TargetInclination).

  // NOTE following piece of code is not used but might still be handy for reference
  if periapsis < 30000 {
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(30000).
    local NewRestrictionList is list(
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde",
      "realnormal_antinormal_timeplus_timemin_prograde_retrograde"
      ).
    local FinalMan is HillClimbLex["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
    ExecuteManeuver(FinalMan).
  } else {
    print "periapsis is looking good".
  }
}

Function InclinationMatcher2 {
  Parameter TargetInclination.

  if abs(ship:orbit:inclination - TargetInclination) > 5 {
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(TargetInclination).
    if abs(ship:orbit:inclination - TargetInclination) > 90 {
      print "over 90 deg diff".
      set NewRestrictionList to list(
        "timeplus_prograde_retrograde",
        "timeplus_prograde_retrograde",
        "timeplus_prograde_retrograde",
        "timeplus_prograde_retrograde",
        "timeplus_prograde_retrograde"
        ).
    } else {
      print "under 90 deg diff".
      set NewRestrictionList to list(
        "timeplus_timemin_prograde_retrograde_radialin_radialout",
        "timeplus_timemin_prograde_retrograde_radialin_radialout",
        "timeplus_timemin_prograde_retrograde_radialin_radialout",
        "timeplus_timemin_prograde_retrograde_radialin_radialout",
        "timeplus_timemin_prograde_retrograde_radialin_radialout"
        ).
    }
    local FinalMan is HillClimbLex["ResultFinder"](NewList, "Inclination", NewScoreList, NewRestrictionList).
    ExecuteManeuver(FinalMan).
  }
}






print "read lib_transfer_burns".
