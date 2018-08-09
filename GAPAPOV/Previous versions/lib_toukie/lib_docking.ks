Function PortGetter {
  Parameter NameOfVessel is ship.
  Parameter PrePickedPort is "none".

  if PrePickedPort = "none" {

    set portlist to list().
    for port in NameOfVessel:partsdubbedpattern("dock"){
      portlist:add(port).
    }

    set ChosenPort to false.
    set PortNumber to 0.
    until ChosenPort = true {
      if portlist[PortNumber]:state = "ready" {
        set DockingPort to portlist[PortNumber].
        portlist:clear.
        set ChosenPort to true.
      } else {
        set PortNumber to PortNumber + 1.
      }
    }
  } else {
    set DockingPort to PrePickedPort.
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

  lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.
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

  Lock DistanceInFrontOfPort to TargetDockingPort:portfacing:vector:normalized * Distance.
  Lock ShipToDIFOP to TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceInFrontOfPort.
  Lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  until ShipDockingPort:state <> "ready" {
    Translate((ShipToDIFOP:normalized*Speed) - RelativeVelocity).
    clearvecdraws().
    vecdraw(TargetDockingPort:position, DistanceInFrontOfPort, RGB(1,0,0), "DistanceInFrontOfPort", 1.0, true, 0.2).
    vecdraw(v(0,0,0), ShipToDIFOP, RGB(0,1,0), "ShipToDIFOP", 1.0, true, 0.2).
    set DistanceVector to (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition).
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

  Lock RelativePosition to ship:position - TargetDockingPort:position.
  Lock SafetyBubbleVector to (RelativePosition:normalized*distance) - RelativePosition.
  Lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  set BreakLoop to false.
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

  Lock SideDirection to TargetDockingPort:ship:facing:starvector.
  if abs(SideDirection*TargetDockingPort:portfacing:vector) = 1 {
    Lock SideDirection to TargetDockingPort:ship:facing:topvector.
  }

  Lock DistanceNextToPort to SideDirection:normalized*Distance.

  if (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition - DistanceNextToPort):mag <
     (TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceNextToPort):mag {
       Lock DistanceNextToPort to (-1*SideDirection*Distance).
     }

  Lock ShipToDNTP to TargetDockingPort:nodeposition - ShipDockingPort:nodeposition + DistanceNextToPort.
  Lock RelativeVelocity to ship:velocity:orbit - TargetDockingPort:ship:velocity:orbit.

  set BreakLoop to false.
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
  PortGetter(ship, "none").
  set ShipDockingPort to DockingPort.
  PortGetter(TargetDestination, "none").
  set TargetDockingPort to DockingPort.

  ShipDockingPort:controlfrom.
  SAS off.
  SteeringTarget(TargetDockingPort:ship).
  RCS on.

  print "Ensuring range 100m".
  EnsureRange(ShipDockingPort, TargetDockingPort, 100, 2).
  print "Killing relative velocity".
  KillRelVelRCS(TargetDockingPort).
  print "Sideways approach 100m".
  SidewaysApproach(ShipDockingPort, TargetDockingPort, 100, 1).
  print "Approach 100m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 100, 1).
  print "Approach 50m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 50, 3).
  print "Approach 20m".
  ApproachDockingPort(ShipDockingPort, TargetDockingPort, 20, 2).
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

print "read lib_docking".
