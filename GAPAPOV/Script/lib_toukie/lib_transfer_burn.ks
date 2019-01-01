

{

global TX_lib_transfer_burn is lexicon(
  "InsertionBurn", InsertionBurn@,
  "ExitSOI", ExitSOI@,
  "CorrectionBurn", CorrectionBurn@,
  "FinalCorrectionBurn", FinalCorrectionBurn@,
  "MoonInsertionBurn", MoonInsertionBurn@,
  "MoonCorrectionBurn", MoonCorrectionBurn@,
  "MoonPostEncounterBurn", MoonPostEncounterBurn@,
  "InclinationMatcher2", InclinationMatcher2@,
  "MoonToMoonInsertionBurn", MoonToMoonInsertionBurn@
  ).
  local TXStopper is "[]".
///
/// INTERPLANETARY
///

Function InsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.

  TX_lib_warp["WarpToPhaseAngle"](TargetDestination, 1).
  TX_lib_warp["WarpToEjectionAngle"](TargetDestination, 1).
  local ResultList is TX_lib_phase_angle["EjectionAngleVelocityCalculation"](TargetDestination).
  local InsertionBurnDv is ResultList[1].
  HUDtext("Insertion burn " + ResultList, 5, 2, 30, white, true).

  local NewList is list(time:seconds + 300, 0, 0, InsertionBurnDv).

  local NewScoreList is list(TargetDestination, TargetPeriapsis).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("none").

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Interplanetary", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function ExitSOI {
  parameter TargetDestination.

  local SOIChange is time:seconds + eta:transition - 5.
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
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("none").

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Interplanetary", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function FinalCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local NewList is list(time:seconds + 300, 0, 0, 0).

  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("prograde_retrograde").

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "FinalCorrection", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

///
/// MOONS
///

Function MoonInsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  HUDtext("going to a moon", 5, 2, 30, white, true).

  // experimental

  // for explanation why 10 degrees see lib_transfer: function MoonTransfer: line 147
  local PhaseTime1 is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetDestination, ship, ship:body).
  wait 5.
  local PhaseTime2 is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetDestination, ship, ship:body).
  local DegPerSec  is abs(PhaseTime1 - PhaseTime2)/5.
  local TimeForTenDeg is 10/DegPerSec.
  // experimental

  local CombinedSMA is (TargetDestination:orbit:semimajoraxis + ship:altitude + ship:body:radius)/2.
  local RoughDv is TX_lib_other["VisViva"](ship:altitude, CombinedSMA).

  local NewList is list(time:seconds + TimeForTenDeg, 0, 0, RoughDv).
  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is list(
    "retrograde_realnormal_antinormal_radialin_radialout",
    "none",
    "none",
    "none",
    "none"
    ).
  // ^^^ first value retrograde

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "MoonTransfer", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function MoonCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local NewList is list(time:seconds + 180, 0, 0, 0).
  local NewScoreList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("none").

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "MoonTransfer", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
}

Function MoonPostEncounterBurn {
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  print "post correcting".

  // NOTE following piece of code is not used but might still be handy for reference
  if periapsis < 30000 {
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(30000).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal_timeplus_timemin_prograde_retrograde").
    local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Periapsis", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  } else {
    print "periapsis is looking good".
  }

  wait 1.
  print "incl " + abs(ship:orbit:inclination - TargetInclination).
  if abs(ship:orbit:inclination - TargetInclination) < 10 {
    local NewList is list(time:seconds + 30, 0, 0, 0).
    local NewScoreList is list(TargetInclination).
    local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("prograde_retrograde").
    local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Inclination", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  } else {
    print "inclination looking G.O.O.D.".
  }
}

Function InclinationMatcher2 {
  Parameter TargetInclination.

  local TrueAnomAN is 360 - ship:orbit:argumentofperiapsis.
  local TrueAnomDN is TrueAnomAN + 180.

  if TrueAnomAN < 0 {
    set TrueAnomAN to TrueAnomAN + 360.
  }

  if TrueAnomDN > 360 {
    set TrueAnomDN to TrueAnomDN - 360.
  }

  print TrueAnomAN.
  print TrueAnomDN.

  local TimeNeeded is "x".
  local TimeAN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomAN).
  local TimeDN is TX_lib_true_anomaly["ETAToTrueAnomaly"](ship, TrueAnomDN).
  local ThetaChange is abs(ship:orbit:inclination - TargetInclination).

  local ANDv is TX_lib_inclination["DeltaVTheta"](TrueAnomAN, ThetaChange).
  local DNDv is TX_lib_inclination["DeltaVTheta"](TrueAnomDN, ThetaChange).

  local DvNeeded is min(ANDv, DNDv).

  if ANDv < DNDv {
    set TimeNeeded to TimeAN.
    set DvNeeded to -1*DvNeeded.
  } else {
    set TimeNeeded to TimeDN.
  }

  if abs(ship:orbit:inclination - TargetInclination) > 0.1 {
    local NewList is list(time:seconds + TimeNeeded, 0, DvNeeded, 0).
    local NewScoreList is list(TargetInclination).

    local NewRestrictionList is "x".
    if abs(ship:orbit:inclination - TargetInclination) > 90 {
      print "over 90 deg diff".
      set NewRestrictionList to TX_lib_hillclimb_universal["IndexFiveFolderder"]("timeplus_prograde_retrograde").
    } else {
      print "under 90 deg diff".
      set NewRestrictionList to TX_lib_hillclimb_universal["IndexFiveFolderder"]("timeplus_timemin_prograde_retrograde_radialin_radialout").
    }

    local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Inclination", NewScoreList, NewRestrictionList).
    TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
  }
}

///
/// MOON TO MOON (AKA SEMI INTERPLANETARY)
///

Function MoonToMoonInsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.

  local testph is TX_lib_phase_angle["PhaseAngleCalculation"](TargetDestination, ship:body, ship:body:body).
  HUDtext("Phase angle " + testph, 5, 2, 30, red, true).

  TX_lib_warp["WarpToPhaseAngle"](TargetDestination, 1, ship:body, ship:body:body, 10000).
  TX_lib_warp["WarpToEjectionAngle"](TargetDestination, 1, ship:body, ship:body:body).
  local ResultList is TX_lib_phase_angle["EjectionAngleVelocityCalculation"](TargetDestination, ship:body).
  local InsertionBurnDv is ResultList[1].
  HUDtext("Insertion burn " + ResultList, 5, 2, 30, white, true).

  local NewList is list(time:seconds + 300, 0, 0, InsertionBurnDv).
  local NewScoreList is list(TargetDestination, TargetPeriapsis).
  local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("retrograde_realnormal_antinormal_radialin_radialout").

  TX_lib_hillclimb_canceler["HillClimbCancel"]().
  local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](NewList, "Interplanetary", NewScoreList, NewRestrictionList).
  TX_lib_hillclimb_canceler["HillCancelOptionHider"]().

  TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).

}

}

print "read lib_transfer_burns".
