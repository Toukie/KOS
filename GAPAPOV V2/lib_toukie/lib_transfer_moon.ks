// ADD INCLINATION CORRECTION JUST LIKE PLANETS

global TX_lib_transfer_moon is lexicon(
  "MoonTransfer", MoonTransfer@,
  "ReturnFromMoon", ReturnFromMoon@
  ).
local TXStopper is "[]".

// warps to right time and burns
Function MoonInsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  parameter TargetLAN.

  HUDtext("going to a moon", 5, 2, 30, white, true).

  TX_lib_inclination["InclinationMatcher"](TargetDestination).

  TX_lib_warp["WarpToPhaseAngle"](TargetDestination, 5, ship, ship:body).


  local CombinedSMA is (TargetDestination:orbit:semimajoraxis + ship:altitude + ship:body:radius)/2.
  local RoughDv is TX_lib_calculations["VisViva"](ship:altitude, CombinedSMA).

  local PhaseTime1 is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetDestination, ship, ship:body).
  wait 5.
  local PhaseTime2 is TX_lib_phase_angle["CurrentPhaseAngleFinder"](TargetDestination, ship, ship:body).
  local DegPerSec  is abs(PhaseTime1 - PhaseTime2)/5.
  local TimeForTenDeg is 10/DegPerSec.
  local NodeList is list(time:seconds + TimeForTenDeg, 0, 0, RoughDv).
  local ParameterList is list(TargetDestination, TargetPeriapsis, TargetInclination, TargetLAN).
  if TargetLAN = "none" {
    ParameterList:remove(3).
  }
  deletepath(liststat).
  //log ParameterList to liststat.
  global StartLogging is true.

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["MoonInsertionScore"], "time").
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

// performs correction for MoonInsertionBurn
Function MoonCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  parameter TargetLAN.

  local NodeList is list(time:seconds + 180, 0, 0, 1).
  local ParameterList is list(TargetDestination, TargetPeriapsis, TargetInclination, TargetLAN).
  if TargetLAN = "none" {
    ParameterList:remove(3).
  }

  local CurrentScore is TX_lib_hillclimb_score["MoonInsertionScore"](NodeList, ParameterList).
  //log "current correction score: " + CurrentScore to CorrectionLog.
  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["MoonInsertionScore"], "none").
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

// goes from kerbin orbit to mun intercept
Function MoonTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.
  parameter TargetLAN is "none".

  MoonInsertionBurn(TargetDestination, TargetPeriapsis, TargetInclination, TargetLAN).

  local MoonCorrectionBurnNeeded is true.
  if ship:orbit:hasnextpatch {
    if ship:orbit:nextpatch:body = TargetDestination {
      set MoonCorrectionBurnNeeded to false.
    }
  }

  until MoonCorrectionBurnNeeded = false {
    MoonCorrectionBurn(TargetDestination, TargetPeriapsis, TargetInclination, TargetLAN).
    if ship:orbit:hasnextpatch {
      if ship:orbit:nextpatch:body = TargetDestination {
        set MoonCorrectionBurnNeeded to false.
      }
    }
  }

  // normal eta warpto needed here

  local ETAWarpTime is time:seconds + eta:transition + 5.
  warpto(ETAWarpTime).
  wait until time:seconds > ETAWarpTime.
  wait until body = TargetDestination.

  until abs(TargetInclination - ship:orbit:inclination) < 5 {
    local BestNode is TX_lib_inclination["InclinationCorrection"](TargetInclination, 60).
    TX_lib_man_exe["ExecuteManeuver"](BestNode).
  }

  local NodeList is list(time:seconds + 30, 0, 0, 10).
  local ParameterList is list(TargetDestination, TargetPeriapsis, TargetInclination, TargetLAN).
  local Restrictions is "time".
  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["FinalCorrectionScore"], Restrictions, 1, 0.1).

  TX_lib_man_exe["ExecuteManeuver"](BestNode).

  TX_lib_man_exe["Circularization"](periapsis).

}

Function ReturnFromMoon {
  parameter ReturnPe is TX_lib_calculations["BestReturnPe"]().
  parameter CircWhenDone is true.

  local MaxWarp is TX_lib_warp["MaxAcceptableWarp"](ship,0.8).
  set warp to MaxWarp.

  if ship:orbit:hasnextpatch = false {
    local AngleFromPeriapsis is 100.
    until AngleFromPeriapsis < 10 {
      set AngleFromPeriapsis to vang(body:orbit:velocity:orbit, ship:position - body:position).
      wait 0.
    }
  }

  set warp to 0.

  local TargetSMA is ship:altitude + 1.1 * ship:body:soiradius + ship:body:radius.
  local DvNeededForExit is TX_lib_calculations["VisViva"](ship:altitude, TargetSMA).
  local ExitList is list(time:seconds+30, 0, 0, DvNeededForExit).  // this is a decent guess but not accurate
  local ParameterList is list(ReturnPe).
  local Restrictions is "none".

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](ExitList, ParameterList, TX_lib_hillclimb_score["MoonReturnScore"], Restrictions).
  TX_lib_man_exe["ExecuteManeuver"](BestNode).

  local SOIexit is time:seconds + eta:transition + 10.
  warpto(SOIexit).
  wait until time:seconds > SOIexit.
  if CircWhenDone = true {
    TX_lib_man_exe["Circularization"](periapsis).
  }
}

print "read lib_transfer_moon".
