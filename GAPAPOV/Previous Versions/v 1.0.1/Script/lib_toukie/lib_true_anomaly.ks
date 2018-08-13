{

global T_TrueAnomaly is lexicon(
  "TrueAnomalyAtTime", TrueAnomalyAtTime@,
  "TimePeToTa", TimePeToTa@,
  "ETAToTrueAnomaly", ETAToTrueAnomaly@
  ).

FUNCTION TrueAnomalyAtTime {
  Parameter TimeTill.
  Parameter TargetObject.

  set SMA to TargetObject:orbit:semimajoraxis.
  set Radius to (positionat(TargetObject, TimeTill+time:seconds) - ship:body:position):mag .
  set PosVec to positionat(TargetObject, TimeTill+time:seconds) - ship:body:position .
  set VelVec to velocityat(TargetObject, TimeTill+time:seconds):orbit.
  set NegCheck to vdot(VelVec, PosVec).
  set Ecc to TargetObject:orbit:Eccentricity.
  if  Ecc = 0 {
    set Ecc to 10^(-1*10).
  }
  set CurrentTrueAnomaly to ARCcos((((SMA*(1-Ecc^2))/Radius)-1)/Ecc).

  if NegCheck < 0 {
    set CurrentTrueAnomaly to 360 - CurrentTrueAnomaly.
  }
}

FUNCTION TimePeToTa {
  Parameter TargetObject.
  Parameter TADeg.

  set Ecc to TargetObject:orbit:Eccentricity.
  set SMA to TargetObject:orbit:semimajoraxis.
  set EccAnomDeg to ARCtan2(SQRT(1-Ecc^2)*sin(TADeg), Ecc + cos(TADeg)).
  set EccAnomRad to EccAnomDeg * (constant:pi/180).
  set MeanAnomRad to EccAnomRad - Ecc*sin(EccAnomDeg).
  return MeanAnomRad / SQRT(TargetObject:orbit:body:mu / SMA^3).
}

FUNCTION ETAToTrueAnomaly {
  Parameter TargetObject.
  Parameter DesiredTrueAnomaly.
  Parameter TimeTill is 0.

  TrueAnomalyAtTime(TimeTill, TargetObject).

  set TargetTime  to TimePeToTa(TargetObject, DesiredTrueAnomaly).
  set CurrentTime to TimePeToTa(TargetObject, CurrentTrueAnomaly).

  set TimeTillDesiredTrueAnomaly to TargetTime - CurrentTime.

  if TimeTillDesiredTrueAnomaly < 0 {
    set TimeTillDesiredTrueAnomaly to TimeTillDesiredTrueAnomaly + TargetObject:orbit:period.
  }
}
}
print "read lib_true_anomaly".
