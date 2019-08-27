global TX_lib_transfer_planet is lexicon(
  "InterplanetaryTransfer", InterplanetaryTransfer@,
  "CorrectionBurn", CorrectionBurn@,
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

  local StartBody is ship:body.
  until ship:body <> StartBody {
    local SOIChange is time:seconds + eta:transition + 5.
    warpto(SOIChange).
    wait until time:seconds > SOIChange.
  }
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
  parameter TargetInclination.
  parameter StepSize is 0.01.

  local NodeList is list(time:seconds + 300, 0, 0, -1).
  local ParameterList is list(TargetDestination, TargetPeriapsis, TargetInclination).
  local Restrictions is "none".
  global DvModifier is 0.01.

  local BestNode  is "".
  local BestNode1 is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["InterplanetaryScore"], Restrictions, -1, StepSize).
  local BestNode2 is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["InterplanetaryScore"], Restrictions, 1, StepSize).

  local Score1 is TX_lib_hillclimb_score["InterplanetaryScore"](BestNode1, ParameterList).
  local Score2 is TX_lib_hillclimb_score["InterplanetaryScore"](BestNode2, ParameterList).

  if Score1 < Score2 {
    set BestNode to BestNode1.
  } else {
    set BestNode to BestNode2.
  }

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

  local BestNode  is "".
  local BestNode1 is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["PlanetFinalCorrectionScore"], Restrictions, -1, 0.1).
  local BestNode2 is TX_lib_hillclimb_main["Hillclimber"](NodeList, ParameterList, TX_lib_hillclimb_score["PlanetFinalCorrectionScore"], Restrictions, 1, 0.1).

  local Score1 is TX_lib_hillclimb_score["PlanetFinalCorrectionScore"](BestNode1, ParameterList).
  local Score2 is TX_lib_hillclimb_score["PlanetFinalCorrectionScore"](BestNode2, ParameterList).

  if Score1 < Score2 {
    set BestNode to BestNode1.
  } else {
    set BestNode to BestNode2.
  }

  TX_lib_man_exe["ExecuteManeuver"](BestNode).
}

Function InterplanetaryTransfer {
  Parameter TargetDestination.
  Parameter TargetPeriapsis.
  Parameter TargetInclination.

  set target to TargetDestination.

  InsertionBurn(TargetDestination, TargetPeriapsis).
  local CorrectionBurnNeeded is ExitSOI(TargetDestination).

  local InterceptNode is TX_lib_lambert_solver["GiveIntercept"](ship, TargetDestination).
  TX_lib_man_exe["ExecuteManeuver"](InterceptNode).

  until CorrectionBurnNeeded = false {
    CorrectionBurn(TargetDestination, TargetPeriapsis, TargetInclination).
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

    add node(BestNode[0], BestNode[1], BestNode[2], BestNode[3]).
    wait 0.
    local NewInc is nextnode:orbit:inclination.
    remove nextnode.
    if abs(TargetInclination - NewInc) < 15 {
      TX_lib_man_exe["ExecuteManeuver"](BestNode).
    } else {
      break.
    }
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

  TX_lib_man_exe["Circularization"]("periapsis").
  TX_lib_inclination["InclinationSetter"](TargetInclination).
  TX_lib_man_exe["CircOrbitTarHeight"](TargetPeriapsis).
}

print "read lib_transfer_planet".
