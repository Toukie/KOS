Function PhaseAngleCalculation {
  Parameter TargetDestination.
  Parameter StartingPoint is ship:body.
  Parameter ReferenceBody is sun.
  Parameter ReturnValue is false.

  set SMA1 to StartingPoint:orbit:semimajoraxis.
  set SMA2 to TargetDestination:orbit:semimajoraxis.

  set SMA3 to SMA1+SMA2.

  set TransitTime to constant:pi*sqrt((SMA3^3)/(8*ReferenceBody:mu)).
  set TargetPhaseAngle  to 180-sqrt(ReferenceBody:mu/SMA2)*(TransitTime/SMA2)*(180/constant:pi).

  until TargetPhaseAngle < 360 {
    set TargetPhaseAngle to TargetPhaseAngle - 360.
  }

  until TargetPhaseAngle > 0 {
    set TargetPhaseAngle to TargetPhaseAngle + 360.
  }

  if ReturnValue = true {
    return TargetPhaseAngle.
  }
}

Function CurrentPhaseAngleFinder {

  Parameter TargetPlanet.
  Parameter StartingBody is ship:body.
  Parameter ReferenceBody is sun.
  Parameter ReturnValue is false.

  set CurrentPhaseAngle to vang(TargetPlanet:position - ReferenceBody:position, StartingBody:position - ReferenceBody:position).
  set vcrsCurrentPhaseAngle to vcrs(TargetPlanet:position - ReferenceBody:position, StartingBody:position - ReferenceBody:position).
  if vdot(v(1,1,1), vcrsCurrentPhaseAngle) <= 0 {
    set CurrentPhaseAngle to 360 - CurrentPhaseAngle.
  }

  if ReturnValue = true {
    return CurrentPhaseAngle.
  }
}

Function GetGrandparentBody {
  Parameter TargetObject is ship.
  if TargetObject:body:hasbody {
    set GrandparentBody to TargetObject:body:body.
  }
  else {
    set GrandparentBody to Sun.
  }
}

Function EjectionAngleVelocityCalculation {

  parameter TargetDestination.

  GetGrandparentBody().

  set ShipParentSMA to ship:body:orbit:semimajoraxis.
  set ShipSMA to ship:orbit:semimajoraxis.
  set TargetDesSMA to TargetDestination:orbit:semimajoraxis.

  set SOIExitVel  to sqrt(GrandparentBody:mu/ShipParentSMA) * (sqrt((2*TargetDesSMA)/(ShipParentSMA+TargetDesSMA))-1).
  set EjectionVel to sqrt(SOIExitVel^2 + (2*ship:body:mu)/(ship:orbit:periapsis+ship:body:radius)).

  set firstE to ((EjectionVel^2)/2) - (ship:body:mu/ShipSMA).
  set AngVel to ShipSMA*EjectionVel.
  set anotherE to sqrt(1+(2*firstE*angvel^2)/ship:body:mu^2).
  set EjectionAng to 180 - arccos(1/anotherE).

  set CurrentVel to SQRT(ship:body:mu * ((2/(ship:altitude+ship:body:radius)) - (1/ship:orbit:semimajoraxis)) ).
  set InsertionBurnDV to EjectionVel-CurrentVel.
}

print "read lib_phaseangle".
