@lazyglobal off.

{

global T_GAPAPOV is lexicon(
  "GAPAPOV", GAPAPOV@
  ).

Function GAPAPOV {
  Parameter GivenParameterList.

  local TargetVessel is "x".
  local TargetBody is "x".
  local TargetPeriapsis is "x".
  local TargetInclination is "x".
  local TarIsPlanet is "x".
  local NoAccidentalIntercept is "x".
  local CurIsPlanet is "x".

  if GivenParameterList:length = 1 {
    set TargetVessel to vessel(GivenParameterList[0]).
    print TargetVessel.
    set TargetBody to TargetVessel:body.
    set TargetPeriapsis to TargetVessel:orbit:periapsis.
    set TargetInclination to TargetVessel:orbit:Inclination.
  } else {
    set TargetBody to GivenParameterList[0].
    set TargetPeriapsis to GivenParameterList[1].
    set TargetInclination to GivenParameterList[2].
  }


  if TargetInclination = 0 {
    set TargetInclination to 0.01.
  }

  // is TargetBody a moon or a planet?
  if TargetBody:body = sun {
    set TarIsPlanet to true.
    set NoAccidentalIntercept to true.
  } else {
    set TarIsPlanet to false.
    set NoAccidentalIntercept to false.
  }

  // is our starting pos a moon or planet?
  if ship:body:body = sun {
    set CurIsPlanet to true.
  } else {
    set CurIsPlanet to false.
  }

  if ship:body = TargetBody and TargetVessel = "x" {
    print "already in orbit around " + ship:body:name.
  }

  if TargetVessel <> "x" {
    clearscreen.
    HUDtext("Rendezvous is go", 5, 2, 30, red, true).
    T_Rendezvous["CompleteRendezvous"](TargetVessel).
    HUDtext("Rendezvous cleared, docking...", 5, 2, 30, red, true).
    T_Docking["Dock"](TargetVessel).
  }


  if ship:body = TargetBody {
    wait 0.
  } else if CurIsPlanet = false {

    if TargetBody:body = ship:body:body {
      // Mun Minmus situation
    } else if TarIsPlanet = true and ship:body:body = TargetBody {
      T_Transfer["MoonToReferencePlanet"](ship:body, ship:body:body, TargetPeriapsis, TargetInclination).
    } else {
      T_Transfer["MoonToReferencePlanet"](ship:body, ship:body:body).
    }
  }

  if ship:body:body = sun {
    set CurIsPlanet to true.
  } else {
    set CurIsPlanet to false.
    print "error??".
  }

  if ship:body = TargetBody {
    wait 0.
  } else if CurIsPlanet = true {

    if TarIsPlanet = true {
      T_Transfer["InterplanetaryTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
    }

    if TarIsPlanet = false {
      if TargetBody:body = ship:body {
        T_Transfer["MoonTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
        HUDtext("We've arrived", 5, 2, 30, red, true).
      }
      else if TargetBody:body <> ship:body {
        local TemporaryDestination is TargetBody:body.
        local TemporaryPeriapsis is 0.5*(TargetBody:orbit:semimajoraxis - TargetBody:body:radius).
        T_Transfer["InterplanetaryTransfer"](TemporaryDestination, TemporaryPeriapsis, TargetInclination, false).
        clearscreen.
        T_Transfer["MoonTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
      }
    }
  }


  clearscreen.
  print "all done".
}

}
