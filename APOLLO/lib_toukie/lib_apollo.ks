global TX_lib_apollo is lexicon(
  "APOLLO", APOLLO@
  ).
local TXStopper is "[]".

////
deletepath(TXlog).
////

Function APOLLO {
  Parameter GivenParameterList.

  TX_lib_necessities["DoNecessities"]().

  local CurBodyIsPlanet   is "?".
  local TargetVessel      is "?".
  local TargetBody        is "?".
  local TargetPeriapsis   is "?".
  local TargetInclination is "?".
  local TargetLatitude    is "?".
  local TargetLongitude   is "?".
  local PreInclination    is "?".
  local Type is GivenParameterList[0].

  local BodyList is list().
  list bodies in BodyList.
  for SomeBody in BodyList {
    print SomeBody.
    print GivenParameterList[1].
    if SomeBody = GivenParameterList[1] {
      set TargetBody to SomeBody.
    }

    if SomeBody:name = GivenParameterList[1] {
      set TargetBody to SomeBody.
    }
  }

  print "---".
  print TargetBody.

  print "-=-=-".
  print GivenParameterList.
  for i in GivenParameterList {
    print i:typename.
  }

  if Type = "Transfer" {
    set TargetPeriapsis   to GivenParameterList[2].
    set TargetInclination to GivenParameterList[3].
  }

  if Type = "Rendezvous" {
    set TargetVessel      to vessel(GivenParameterList[1]).
    set TargetBody        to TargetVessel:body.
    set TargetPeriapsis   to 0.8 * TargetVessel:orbit:periapsis.
    set TargetInclination to TargetVessel:orbit:inclination.
  }

  if Type = "Landing" {
    if TargetBody:atm:exists {
      set TargetPeriapsis to TargetBody:atm:height + 250000.
    } else {
      if TargetBody = gilly {
        set TargetPeriapsis to 25000.
      } else {
        set TargetPeriapsis to 250000.
      }
    }
    set PreInclination    to GivenParameterList[2].
    set TargetInclination to abs(PreInclination:toscalar).
    set TargetLatitude    to GivenParameterList[2]:toscalar.
    set TargetLongitude   to GivenParameterList[3]:toscalar.
  }

  local CurBodyIsPlanet is ship:body:body = Sun.

  // landed on Mun
  if ship:status = "prelaunch" or ship:status = "landed" {
    local CountDown is 5.
    until CountDown = 0 {
      HUDtext(CountDown + "...", 5, 2, 30, white, true).
      wait 1.
      set CountDown to CountDown-1.
    }
    HUDtext("Ignition", 5, 2, 30, white, true).

    local TemporaryPeriapsis is "?".
    local TemporaryInclination is 0.

    if ship:body = TargetBody and type <> "Rendezvous" {
      set TemporaryPeriapsis to TargetPeriapsis.
      set TemporaryInclination to TargetInclination.
    } else {
      if type = "Rendezvous" {
        set TemporaryInclination to TargetInclination.
      } else {
        set TemporaryInclination to 0.
      }
      if TargetBody:atm:exists {
        set TemporaryPeriapsis to TargetBody:atm:height + 100000.
      } else {
        set TemporaryPeriapsis to 150000.
      }
    }

    log "MainLaunch" to TXlog.
    log "Circularization" to TXlog.
    TX_lib_ascent["MainLaunch"](TemporaryPeriapsis, TemporaryInclination).
    TX_lib_man_exe["Circularization"]().
  }

  // Kerbin <> Sun or Eve , return to kerbin
  if ship:body:body <> TargetBody:body and CurBodyIsPlanet = false {
    if ship:body:body <> TargetBody {
      // Mun -> Eve or Gilly
      log "ReturnFromMoon 1" to TXlog.
      TX_lib_transfer_moon["ReturnFromMoon"](750000).
    } else {
      // Mun -> Kerbin
      log "ReturnFromMoon 2" to TXlog.
      TX_lib_transfer_moon["ReturnFromMoon"](TargetPeriapsis).
    }
  }

// going from kerbin to Gilly (but just eve for now)
  if TargetBody:body <> Sun {
   if ship:body:body = TargetBody:body:body and ship:body <> TargetBody:body {
     log "InterplanetaryTransfer 1" to TXlog.
     TX_lib_transfer_planet["InterplanetaryTransfer"](TargetBody:body, TargetPeriapsis, 0).
   }
 }

  // in orbit around mun now
  // Mun -> Minmus
  // also Kerbin -> Eve
  if ship:body:body = TargetBody:body and ship:body <> TargetBody {
    log "InterplanetaryTransfer 2" to TXlog.
    TX_lib_transfer_planet["InterplanetaryTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
  }


  // Moon transfer
  // Eve -> Gilly
  // kerbin -> Mun
  if ship:body = TargetBody:body {
    log "MoonTransfer" to TXlog.
    TX_lib_transfer_moon["MoonTransfer"](TargetBody, TargetPeriapsis, TargetInclination).
  }

  // Mun -> Mun
  // also Kerbin -> Kerbin
  if ship:body = TargetBody {
    if PreInclination = "000" {
      set TargetInclination to ship:orbit:inclination.
    }
    log "InclinationSetter" to TXlog.
    log "CircOrbitTarHeight" to TXlog.
    if PreInclination <> "000" {
      TX_lib_inclination["InclinationSetter"](TargetInclination).
      TX_lib_man_exe["CircOrbitTarHeight"](TargetPeriapsis).
    }
  }

  // at right planet with decent orbit parameters
  // check for landing and or Rendezvous

  if Type = "Rendezvous" {
    log "FullRendezvous" to TXlog.
    log "dock" to TXlog.
    set target to TargetVessel.
    TX_lib_rendezvous["FullRendezvous"](TargetVessel).
    TX_lib_docking["dock"](TargetVessel).
  }

  if type = "Landing" {
    print TargetLatitude.
    print (TargetLatitude:istype("scalar")).
    print TargetLongitude.
    print (TargetLongitude:istype("scalar")).
    if GivenParameterList[2] = "000" or GivenParameterList[3] = "000" {
      log "SuicideBurn" to TXlog.
      TX_lib_landing["SuicideBurn"]().
    } else {
      log "FullLanding " + TargetLatitude + ", " + TargetLongitude to TXlog.
      TX_lib_precision_landing["FullLanding"](TargetLatitude, TargetLongitude).
    }

  }

  edit TXlog.
}

















.
