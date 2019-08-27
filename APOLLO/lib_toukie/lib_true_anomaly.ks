global TX_lib_true_anomaly is lexicon(
  "ETAToTrueAnomaly", ETAToTrueAnomaly@
  ).
local TXStopper is "[]".

Function ETAToTrueAnomaly {

  parameter TargetObject.
  parameter TADeg. // true anomaly in degrees

  local Ecc is "X".
  local MAEpoch is "X".
  local SMA is "X".
  local Mu is "X".
  local Epoch is "X".

  if hasnode {
    if nextnode:orbit:hasnextpatch {
      set Ecc to nextnode:orbit:nextpatch:eccentricity.
      set MAEpoch to nextnode:orbit:nextpatch:meananomalyatepoch * (constant:pi/180).
      set SMA to nextnode:orbit:nextpatch:semimajoraxis.
      set Mu to nextnode:orbit:nextpatch:body:mu.
      set Epoch to nextnode:orbit:nextpatch:epoch.
    } else {
      set Ecc to nextnode:orbit:eccentricity.
      set MAEpoch to nextnode:orbit:meananomalyatepoch * (constant:pi/180).
      set SMA to nextnode:orbit:semimajoraxis.
      set Mu to nextnode:orbit:body:mu.
      set Epoch to nextnode:orbit:epoch.
    }
  } else {
    set Ecc to TargetObject:orbit:eccentricity.
    set MAEpoch to TargetObject:orbit:meananomalyatepoch * (constant:pi/180).
    set SMA to TargetObject:orbit:semimajoraxis.
    set Mu to TargetObject:orbit:body:mu.
    set Epoch to TargetObject:orbit:epoch.
  }

  if  Ecc = 0 {
    set Ecc to 10^(-10).
  }

  if Ecc > 1 {
    set ecc to 0.99.
  }

  if SMA < 0 {
    print "SMA is negative due to extreme eccentricity!".
    print "An eccentricity of over 1 is not a stable orbit".
    print "Eccentricity: " + ship:orbit:eccentricity.
    print "***************************".
  }

  local EccAnomDeg is ARCtan2(SQRT(1-Ecc^2)*sin(TADeg), Ecc + cos(TADeg)).
  local EccAnomRad is EccAnomDeg * (constant:pi/180).
  local MeanAnomRad is EccAnomRad - Ecc*sin(EccAnomDeg).

  local DiffFromEpoch is MeanAnomRad - MAEpoch.
  until DiffFromEpoch > 0 {
    set DiffFromEpoch to DiffFromEpoch + 2 * constant:pi.
  }
  local MeanMotion is SQRT(Mu / SMA^3).
  local TimeFromEpoch is DiffFromEpoch/MeanMotion.
  local TimeTillETA is TimeFromEpoch + Epoch - time:seconds.

  until TimeTillETA >= 0 {
    set TimeTillETA to TimeTillETA + TargetObject:orbit:period.
  }

  return TimeTillETA.
}

print "read lib_true_anomaly".
