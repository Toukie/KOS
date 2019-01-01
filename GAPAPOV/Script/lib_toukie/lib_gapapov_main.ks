{

global TX_lib_gapapov_main is lexicon(
  "GAPAPOV", GAPAPOV@
  ).
local TXStopper is "[]".

  Function GAPAPOV {
    Parameter GivenParameterList.

    local CurBodyIsPlanet   is "?".
    local TarBodyIsPlanet   is "?".
    local RendezvousNeeded  is "?".
    local TargetVessel      is "?".
    local TargetBody        is "?".
    local TargetPeriapsis   is "?".
    local TargetInclination is "?".
    local FinishProcedure   is false.

    if GivenParameterList:length = 1 {
      set RendezvousNeeded  to true.
      set TargetVessel      to vessel(GivenParameterList[0]).
      set TargetBody        to TargetVessel:body.
      set TargetPeriapsis   to TargetVessel:orbit:periapsis.
      set TargetInclination to TargetVessel:orbit:inclination.
    } else if GivenParameterList:length = 3 {
      set RendezvousNeeded  to false.
      set TargetBody        to GivenParameterList[0].
      set TargetPeriapsis   to GivenParameterList[1].
      set TargetInclination to GivenParameterList[2].
    }

    //// EXPERIMENTAL

    when alt:radar > ship:body:atm:height then {
      wait 2.
      TX_lib_other["SolarPanelAction"]("extend").
    }

    if ship:status = "prelaunch" or ship:status = "landed" {
      local CountDown is 5.
      until CountDown = 0 {
        HUDtext(CountDown + "...", 5, 2, 30, white, true).
        wait 1.
        set CountDown to CountDown-1.
      }
      HUDtext("Ignition", 5, 2, 30, white, true).
      local TemporaryInclination is TargetInclination.

      if TargetBody:body = ship:body {
        //HUDtext("going to a moon", 5, 2, 30, white, true).
        set TemporaryInclination to TargetBody:orbit:inclination.
        if TemporaryInclination = 0 {
          set TemporaryInclination to 0.000001.
        }
      } else if ship:body:body <> "Sun" {
        //HUDtext("going to a planet", 5, 2, 30, white, true).
        set TemporaryInclination to 0.000001.
      } else {
        //HUDtext("staying in " +ship:body:name + "'s sphere of influence", 5, 2, 30, white, true).
      }

      local TemporaryPeriapsis is TargetPeriapsis.
      if ship:body <> TargetBody {
        set TemporaryPeriapsis to 100000.
      }
      TX_lib_atmos_launch["MainLaunch"](TemporaryPeriapsis, TemporaryInclination).
      TX_lib_atmos_launch["Circularize"]().
    }

    //// EXPERIMENTAL

    if TargetInclination = 0 {
      set TargetInclination to 0.000001.
    }

    if ship:body = TargetBody and RendezvousNeeded = false {
      TX_lib_transfer["ChangeOrbit"](TargetPeriapsis, TargetInclination).
      set FinishProcedure to true.
    } else {
	  local CircParameter is TX_lib_gui["CircGUI"]().

    if CircParameter <> "cancel" {
      local InputList is list().

      if CircParameter = "periapsis" {
      set InputList to list(time:seconds + eta:periapsis, 0, 0, 0).
      } else {
          set InputList to list(time:seconds + eta:apoapsis, 0, 0, 0).
      }

      local NewScoreList is list().
      local NewRestrictionList is TX_lib_hillclimb_universal["IndexFiveFolderder"]("realnormal_antinormal").
      local FinalMan is TX_lib_hillclimb_universal["ResultFinder"](InputList, "Circularize", NewScoreList, NewRestrictionList).
      TX_lib_hillclimb_man_exe["ExecuteManeuver"](FinalMan).
    }
	}

    if ship:body:body:name <> "Sun" {
      set CurBodyIsPlanet to false.
    } else {
      set CurBodyIsPlanet to true.
    }

    if TargetBody:body:name <> "Sun" {
      set TarBodyIsPlanet to false.
    } else {
      set TarBodyIsPlanet to true.
    }

    if FinishProcedure = false {
      if CurBodyIsPlanet  = false {
        if ship:body:body = TargetBody:body {
          TX_lib_transfer["MoonToMoon"](TargetBody, TargetPeriapsis, TargetInclination).
          set FinishProcedure to true.
        } else {
          HUDtext("Going back to " + ship:body:body:name, 5, 2, 30, white, true).
          TX_lib_transfer["MoonToReferencePlanet"](ship:body, ship:body:body, TargetPeriapsis, TargetInclination).
          TX_lib_transfer["ChangeOrbit"](TargetPeriapsis, TargetInclination).
          if ship:body = TargetBody {
            set FinishProcedure to true.
          }
        }
      }
    }

    if FinishProcedure = false {
      local TemporaryDestination is TargetBody.
      if TarBodyIsPlanet = false {
        set TemporaryDestination to TargetBody:body.
      }
      if TemporaryDestination <> ship:body {
        TX_lib_transfer["InterplanetaryTransfer"](TemporaryDestination, TargetPeriapsis, TargetInclination).
      }

      if TarBodyIsPlanet = false {
        TX_lib_transfer["MoonTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
      }
    }

    if RendezvousNeeded = true {
      HUDtext("Rendezvous is go", 5, 2, 30, red, true).
      TX_lib_rendezvous["CompleteRendezvous"](TargetVessel).
      HUDtext("Rendezvous cleared, docking...", 5, 2, 30, red, true).
      TX_lib_docking["Dock"](TargetVessel).
    }
  }


}
