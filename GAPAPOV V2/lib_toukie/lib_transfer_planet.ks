global TX_lib_transfer_planet is lexicon(
  "InterplanetaryTransfer", InterplanetaryTransfer@,
  "FinalCorrectionBurn", FinalCorrectionBurn@
  ).
local TXStopper is "[]".


Function InsertionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.

  TX_lib_warp["WarpToPhaseAngle"](TargetDestination, 1).
  TX_lib_warp["WarpToEjectionAngle"](TargetDestination, 1).
  local ResultList is TX_lib_phase_angle["EjectionAngleVelocityCalculation"](TargetDestination).
  local InsertionBurnDv is ResultList[1].
  wait until kuniverse:timewarp:rate = 1.
  HUDtext("Insertion burn " + ResultList, 5, 2, 30, white, true).

  local NodeList is list(time:seconds + 20, 0, 0, InsertionBurnDv).

  local ParameterList is list(TargetDestination, TargetPeriapsis).
  local Restrictions is "time".

  global OwnBoundaries is list("radial_normal_prograde", list(-50, 50), list(-50, 50), list(InsertionBurnDv-50, InsertionBurnDv+50)). // defaults for ALL node values: radial normal etc
  //local OwnBoundaries is list("time_prograde", list(time1, time2), list(pro1, pro2)).
  //log OwnBoundaries to ("0:/aplog").

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["InterplanetaryScore"], Restrictions, 1, 0.01).
  HUDtext("Found good node ", 5, 2, 30, white, true).
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
  HUDtext("Perfomed burn ", 5, 2, 30, white, true).
}

Function ExitSOI {
  parameter TargetDestination.

  local SOIChange is time:seconds + eta:transition + 5.
  warpto(SOIChange).
  wait until time:seconds > SOIChange.
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

  local NodeList is list(time:seconds + 300, 0, 0, -1).
  local ParameterList is list(TargetDestination, TargetPeriapsis).
  local Restrictions is "none".
  global DvModifier is 0.01.

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["InterplanetaryScore"], Restrictions, 1, 0.01).
  unset DvModifier.
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function FinalCorrectionBurn {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  local NodeList is list(time:seconds + 300, 0, 0, 1).

  local ParameterList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local Restrictions is "none".

  local BestNode is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["PlanetFinalCorrectionScore"], Restrictions, 1, 0.1).
  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function InterplanetaryTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  InsertionBurn(TargetDestination, TargetPeriapsis).
  local CorrectionBurnNeeded is ExitSOI(TargetDestination).

  add node(time:seconds, 0, 0, 0).
  wait 0.
  local InterceptTime is TX_lib_closest_approach["ClosestApproachFinder"](TargetDestination, true).
  remove nextnode.
  deletepath(interceptlog).
  log InterceptTime to interceptlog.

  CorrectionBurn(TargetDestination, TargetPeriapsis).
  wait 2.
  HUDtext("CorrectionBurn needed: " + CorrectionBurnNeeded, 5, 2, 30, white, true).

  until CorrectionBurnNeeded = false {
    CorrectionBurn(TargetDestination, TargetPeriapsis).
    if ship:orbit:hasnextpatch = true {
      if ship:orbit:nextpatch:body = TargetDestination {
        set CorrectionBurnNeeded to false.
        clearscreen.
        wait 2.
        print "All go!".
      }
    }
  }

  local TimeTillIntercept is time:seconds + eta:transition + 5.
  warpto(TimeTillIntercept).
  wait until time:seconds > TimeTillIntercept.

  until abs(TargetInclination - ship:orbit:inclination) < 15 {
    local BestNode is TX_lib_inclination["InclinationCorrection"](TargetInclination, 60).
    TX_lib_man_exe["ExecuteManeuver"](BestNode).
  }

  FinalCorrectionBurn(TargetDestination, TargetPeriapsis, TargetInclination).
  // in intercept with planet now (and potentially moon intercept)

  local AccidentalMoonIntercept is false.

  if ship:orbit:hasnextpatch = true {
    if ship:orbit:nextpatch:hasnextpatch = true {
      if ship:orbit:nextpatch:nextpatch:body = TargetDestination {
        if eta:transition < eta:periapsis { // if periapsis is before the intercept it wont matter
          HUDtext("Accidental moon intercept", 5, 2, 30, white, true).
          set AccidentalMoonIntercept to true.
        }
      }
    }
  }

  if AccidentalMoonIntercept = true {
    TX_lib_transfer_moon["ReturnFromMoon"](TargetPeriapsis, false).
    FinalCorrectionBurn(TargetDestination, TargetPeriapsis, TargetInclination).
  }

  TX_lib_man_exe["Circularization"](periapsis).
  TX_lib_inclination["InclinationSetter"](TargetInclination).
}

print "read lib_transfer_planet".
