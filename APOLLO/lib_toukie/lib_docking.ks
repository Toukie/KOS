global TX_lib_docking is lexicon(
  "Dock", Dock@,
  "CheckIfDocked", CheckIfDocked@,
  "FuelTransfer", FuelTransfer@,
  "Undock", Undock@,
  "MoveAway", MoveAway@
  ).
local TXStopper is "[]".

Function PortGetter {
  Parameter NameOfVessel is ship.
  Parameter PrePickedPort is "none".
  if PrePickedPort = "none" {

    local portlist is list().
    for port in NameOfVessel:partsdubbedpattern("dock"){
      portlist:add(port).
    }

    local PortNumber is 0.
    until false {
      if portlist[PortNumber]:state = "ready" {
        return portlist[PortNumber].
      } else {
        set PortNumber to PortNumber + 1.
        if PortNumber = PortList:length {
          print "ERROR NO PORTS READY TO BE USED".
        }
      }
    }
  } else {
    return PrePickedPort.
  }
}

Function Translate {
  Parameter SomeVector.
  if SomeVector:mag > 1 {
    set SomeVector to SomeVector:normalized.
  }

  set ship:control:starboard to SomeVector * ship:facing:starvector.
  set ship:control:fore      to SomeVector * ship:facing:forevector.
  set ship:control:top       to SomeVector * ship:facing:topvector.
}

Function KillRelVelRCS {
  Parameter TargetDockingPort.

  local lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.
  until RelativeVelocity:mag < 0.1 {
    Translate(-1*RelativeVelocity).
  }
  Translate(V(0,0,0)).
}

Function ApproachDockingPort {
  Parameter ShipDockingPort.
  Parameter TargetDockingPort.
  Parameter Distance.
  Parameter Speed.
  Parameter ErrorAllowed is 0.1.

  ShipDockingPort:controlfrom.

  local Lock DistanceInFrontOfPort to TargetDockingPort:portfacing:vector:normalized * Distance.
  local Lock ShipToDIFOP to TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceInFrontOfPort.
  local Lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  until ShipDockingPort:state <> "ready" {
    Translate((ShipToDIFOP:normalized*Speed) - RelativeVelocity).
    clearvecdraws().
    vecdraw(TargetDockingPort:position, DistanceInFrontOfPort, RGB(1,0,0), "DistanceInFrontOfPort", 1.0, true, 0.2).
    vecdraw(v(0,0,0), ShipToDIFOP, RGB(0,1,0), "ShipToDIFOP", 1.0, true, 0.2).
    local DistanceVector is (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition).
    if vang(ShipDockingPort:portfacing:vector, DistanceVector) < 2 and abs(Distance - DistanceVector:mag) < ErrorAllowed {
      break.
    }
  }
  Translate(v(0,0,0)).
}

Function EnsureRange {
  Parameter ShipDockingPort.
  Parameter TargetDockingPort.
  Parameter Distance.
  Parameter Speed.

  local Lock RelativePosition to ship:position - TargetDockingPort:position.
  local Lock SafetyBubbleVector to (RelativePosition:normalized*distance) - RelativePosition.
  local Lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  local BreakLoop is false.
  until BreakLoop = true {
    Translate((SafetyBubbleVector:normalized*speed) - RelativeVelocity).
    if SafetyBubbleVector:mag < 0.1 {
      set BreakLoop to true.
    }
  }
  Translate(v(0,0,0)).
}

Function SidewaysApproach {
  Parameter ShipDockingPort.
  Parameter TargetDockingPort.
  Parameter Distance.
  Parameter Speed.

  ShipDockingPort:controlfrom.

  local lock SideDirection to TargetDockingPort:ship:facing:starvector.
  if abs(SideDirection*TargetDockingPort:portfacing:vector) = 1 {
    Lock SideDirection to TargetDockingPort:ship:facing:topvector.
  }

  local lock DistanceNextToPort to SideDirection:normalized*Distance.

  if (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition - DistanceNextToPort):mag <
     (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceNextToPort):mag {
       Lock DistanceNextToPort to (-1*SideDirection*Distance).
     }

  local lock ShipToDNTP to TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceNextToPort.
  local lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  local BreakLoop is false.
  until BreakLoop = true {
    clearvecdraws().
    vecdraw(TargetDockingPort:position, DistanceNextToPort, RGB(1,0,0), "DistanceNextToPort", 1.0, true, 0.2).
    vecdraw(v(0,0,0), ShipToDNTP, RGB(0,1,0), "ShipToDNTP", 1.0, true, 0.2).
    Translate((ShipToDNTP:normalized*Speed) - RelativeVelocity).
    if ShipToDNTP:mag < 0.1 {
      set BreakLoop to true.
    }
  }
  Translate(v(0,0,0)).
}

Function Dock {
  Parameter TargetDestination.

  clearvecdraws().
  local ShipDockingPort is PortGetter(ship, "none").
  local TargetDockingPort is PortGetter(TargetDestination, "none").

  ShipDockingPort:controlfrom.
  SAS off.
  TX_lib_steering["SteeringTarget"](TargetDockingPort:ship).
  RCS on.

  print "Ensuring range 100m".
  EnsureRange(ShipDockingPort, TargetDockingPort, 100, 4).
  print "Killing relative velocity".
  KillRelVelRCS(TargetDockingPort).
  print "Sideways approach 100m".
  SidewaysApproach(ShipDockingPort, TargetDockingPort, 100, 3).
  print "Approach 100m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 100, 3).
  print "Approach 50m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 50, 3).
  print "Approach 20m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 20, 3).
  print "Approach 10m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 10, 1).
  print "Approach 5m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 5, 0.5).
  print "Approach 1m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 1, 0.3, 0.05).
  print "Approach 0m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 0, 0.1).
  print "Docked".
  clearvecdraws().
  RCS off.
}

Function CheckIfDocked {
  Parameter NameOfVessel is ship.

  local portlist is list().
  for port in NameOfVessel:partsdubbedpattern("dock"){
    portlist:add(port).
  }

  local PortNumber is 0.
  for Port in PortList {
    if portlist[PortNumber]:state:contains("docked") = true {
      return true.
    }
    set PortNumber to PortNumber + 1.
  }
  return false.
}

Function FuelTransfer {
  Parameter FromParts is "default".
  Parameter ToParts is "default".

  local EList is list().
  list elements in EList.

  if FromParts = "default" {
    set FromParts to EList[0].
  }

  if ToParts = "default" {
    set ToParts to EList[1].
  }

  local Foo is transferall("Oxidizer", FromParts, ToParts).
  set Foo:active to true.
  wait until Foo:status = "Finished".

  local Foo is transferall("LiquidFuel", FromParts, ToParts).
  set Foo:active to true.
  wait until Foo:status = "Finished".
}

Function Undock {
  Parameter UndockingShipElement is "default".

  local EList is list().
  list elements in EList.

  if UndockingShipElement = "default" {
    set UndockingShipElement to EList[0].
  }

  local portlist is list().
  local PartList is UndockingShipElement:parts.

  for part in PartList {
    if part:name:contains("dock") {
      portlist:add(part).
    }
  }

  for port in PortList {
    port:undock.
    wait 0.
  }
}

Function MoveAway {
  Parameter Mover is ship.
  local TarList is list().
  list targets in TarList.
  unlock steering.
  sas on.
  rcs on.
  for Tar in TarList {
    if (Mover:position - Tar:position):mag < 50 {
      local lock RelativeVelocity to Mover:velocity:orbit - tar:velocity:orbit.
      until RelativeVelocity:mag > 2 {
        translate(-tar:position:normalized * 2).
      }
      Translate(V(0,0,0)).
      wait 5.
      Translate(V(0,1,0)).
      wait 2.
      Translate(V(0,0,0)).

    }
  }
  sas off.
  rcs off.
}

print "read lib_docking".
