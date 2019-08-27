
global TX_lib_lambert_solver is lexicon(
  "GiveIntercept", GiveIntercept@
).

local TXStopper is "[]".


Function GiveIntercept {
  parameter origin is ship,
      destination is target,
      flightTimeGuess is 0.5*ship:orbit:period.

  global firstBurn is time:seconds + 120.
  global lastBurn is 0.
  if ship:obt:eccentricity > 1 { set lastBurn to time:seconds + 6000. }
  else { set lastBurn to ship:orbit:period * 10. }
  global offsetVec is V(100,0,0).

  global segments is 5.

  LeastDVGivenNothing(origin, destination, flightTimeGuess).
  wait 0.
  local NodeList is list(time:seconds + nextnode:eta, nextnode:radialout, nextnode:normal, nextnode:prograde).
  remove nextnode.
  return NodeList.
}

function LeastDVHelper {
	parameter burnTime,
		  flightTime,
		  origin is ship,
		  destination is target.

	set testNode to GetLambertInterceptNode(origin, destination, burnTime, flightTime, offsetVec).
	set deltaV to testNode:deltav:mag +
		      (velocityat(origin, burnTime+flightTime):orbit - velocityat(destination, burnTime + flightTime):orbit):mag.
	remove testNode.

	return deltaV.
}

function LeastDVGivenBurnTime {
	parameter burnTime is firstBurn,
		  flightTimeGuess is 0,
		  origin is ship,
		  destination is target.

	if flightTimeGuess = 0 {
		local originRadius is (origin:position - origin:body:position):mag.
		local destinationRadius is (destination:position - origin:body:position):mag.
		local radiusSum is originRadius + destinationRadius.

		local hohmannDuration is pi * sqrt(radiusSum*radiusSum*radiusSum/(8*origin:body:mu)).

		set flightTimeGuess to hohmannDuration.
	}

	set testFlightTime to flightTimeGuess.
	set testFlightBurn to LeastDVHelper(firstBurn, flightTimeGuess).
	set oldFlightTime to 0.

	set step to Queue(3600, 600, 60, 30, 10, 5, 1, 0.5, 0.1, 0.05, 0.01).

	until step:length = 0 {
		until testFlightTime = oldFlightTime {
			print "    Testing "+round(testFlightTime,.01)+"+/-"+step:peek().
			set oldFlightTime to testFlightTime.
			set upTime to testFlightTime + step:peek().
			set downTime to testFlightTime - step:peek().
			set upBurn to LeastDVHelper(firstBurn, upTime).
			print "      "+round(upTime,.01)+": "+upBurn+"m/s".
			if upBurn < testFlightBurn {
				set testFlightBurn to upBurn.
				set testFlightTime to upTime.
			} else if downTime > 0 {
				set downBurn to LeastDVHelper(firstBurn, downTime).
				print "      "+round(downTime,.01)+": "+downBurn+"m/s".
				if downBurn < testFlightBurn {
					set testFlightTime to downTime.
					set testFlightBurn to downBurn.
				}
			}
		}
		step:pop().
		set oldFlightTime to 0.
	}

	set LeastDVGivenStartNode to GetLambertInterceptNode(origin, destination, firstBurn, testFlightTime, offsetVec).
	return List(LeastDVGivenStartNode, testFlightTime, testFlightBurn).
}

function LeastDVGivenNothing {
	parameter origin is ship,
		  destination is target,
		  flightTimeGuess is 0.

	if flightTimeGuess = 0 {
		local originRadius is (origin:position - origin:body:position):mag.
		local destinationRadius is (destination:position - origin:body:position):mag.
		local radiusSum is originRadius + destinationRadius.

		local hohmannDuration is pi * sqrt(radiusSum*radiusSum*radiusSum/(8*origin:body:mu)).

		set flightTimeGuess to hohmannDuration.
	}

	local boundsFunc is {
		parameter boundsx, boundsy.
		return boundsx > firstBurn and
			boundsx < firstBurn + lastBurn and
			boundsy > 10.
	}.
	local fitness is {
		parameter fitx, fity.
		return LeastDVHelper(fitx, fity).
	}.
	local patternSearch is {
		parameter patternX, patternY, optimizer.
		local bestVertex is V(x,y,1e10).
		local step is (2^16).
		until step < 0.25 {
			print "Step size: " + step.
			local pattern is List(
				V(x, y, 0),
				V(x, y + step, 0),
				V(x + step, y, 0),
				V(x, y - step, 0),
				V(x - step, y, 0)
			).
			for vertex in pattern {
        print vertex:x.
        print vertex:y.
				if boundsFunc(vertex:x, vertex:y) {
					set vertex:z to fitness(vertex:x, vertex:y).
					print "Testing " + vertex:x + " departure for " + vertex:y + " flight: " + vertex:z.
				} else { set vertex:z to 1e10. }
			}
			set bestVertex to pattern[0].
			for vertex in pattern {
				if optimizer(vertex:z, bestVertex:z) { set bestVertex to vertex. }
			}
			if bestVertex = pattern[0] {
				set step to step / 2.
			} else {
				set x to bestVertex:x.
				set y to bestVertex:y.
			}
		}
		return bestVertex.
	}.
	local x is firstBurn.
	local y is flightTimeGuess.
	// Find local minimum.
	set firstMinimum to patternSearch(x, y, { parameter minx, miny. return minx < miny. }).
	print "First Minimum: +" + firstMinimum:x + " departure for " + firstMinimum:y + " flight.".
	// Find local maximum.
	set firstMaximum to patternSearch(x, y, { parameter maxx, maxy. return maxx > maxy. }).
	print "First Maximum: +" + firstMaximum:x + " departure for " + firstMaximum:y + " flight.".
	// Find next local minimum.
	set secondMinimum to patternSearch(firstMaximum:x + 1, firstMaximum:y, { parameter minx, miny. return minx < miny. }).
	print "Second Minimum: +" + secondMinimum:x + " departure for " + secondMinimum:y + " flight.".

	if firstMinimum:z <= secondMinimum:z {
		set node to GetLambertInterceptNode(origin, destination, firstMinimum:x, firstMinimum:y, offsetVec).
		return List(node, firstMinimum:x, firstMinimum:y).
	} else {
		set node to GetLambertInterceptNode(origin, destination, secondMinimum:x, secondMinimum:y, offsetVec).
		return List(node, firstMinimum:x, firstMinimum:y).
	}

	local testBurnTime is firstBurn.
	local testBurnDV is LeastDVGivenBurnTime(testBurnTime)[2].

	local firstBurnDV is testBurnDV.

	local oldBurnTime is 0.

	local burnTimeStep is Queue(3600, 1200, 600, 300, 60, 30, 10, 5, 1, 0.5, 0.1, 0.05, 0.01).

	local increasing is true.

	print "firstBurn: "+(firstBurn - time:seconds).
	print "lastBurn: "+(firstBurn + lastBurn - time:seconds).

	print "Comparing to "+testBurnDV.

	until burnTimeStep:length = 0 {
		until testBurnTime = oldBurnTime {
			print "Testing "+(testBurnTime-time:seconds)+"+/-"+burnTimeStep:peek()+".".
			set oldBurnTime to testBurnTime.
			local upBurnTime is testBurnTime + burnTimeStep:peek().
			local downBurnTime is testBurnTime - burnTimeStep:peek().
			local upBurnDV is 0.
			local downBurnDV is 0.
			if upBurnTime <= firstBurn + lastBurn {
				local testResult is LeastDVGivenBurnTime(upBurnTime).
				remove testResult[0].
				print "  "+(upBurnTime - time:seconds)+": "+testResult[2]+"m/s".
				if testResult[2] < testBurnDV {
					set increasing to false.
					set testBurnTime to upBurnTime.
					set testBurnDV to testResult[2].
				} else if increasing {
					set testBurnTime to upBurnTime.
					set testBurnDV to testResult[2].
				}
			}
			if increasing = false and downBurnTime >= firstBurn {
				local testResult is LeastDVGivenBurnTime(downBurnTime).
				remove testResult[0].
				print "  "+(downBurnTime - time:seconds)+": "+testResult[2]+"m/s".
				if testResult[2] < testBurnDV {
					set testBurnTime to downBurnTime.
					set testBurnDV to testResult[2].
				}
			}
		}

		burnTimeStep:pop().
		set oldBurnTime to 0.
	}

	return LeastDVGivenBurnTime(testBurnTime)[0].
}

global PI is Constant():PI.
global BaseE is Constant():E.

Function clamp360 {
	parameter deg360.
	if (abs(deg360) > 360) { set deg360 to mod(deg360, 360). }
	until deg360 > 0 {
		set deg360 to deg360 + 360.
	}
	return deg360.
}

Function clamp180 {
	parameter deg180.
	set deg180 to clamp360(deg180).
	//if deg > 180 { return 360 - deg. } // always returned positive, wanted to get negative, but not sure that I'm not exploiting the bug
	if deg180 > 180 { return deg180 - 360. }
	return deg180.
}

Function ptp {
	parameter str.
	local line to "T+" + round(missiontime) + "---" + str.
	print line.
	//hudtext(line, 5, 4, 40, red, false).
	//log line to missionlog.
}

Function alert {
	parameter str.
	hudtext(str, 30, 2, 40, white, false).
	ptp(str).
}

Function warn {
	parameter str.
	hudtext(str, 60, 2, 40, yellow, false).
	ptp(str).
}

Function error {
	parameter str.
	hudtext(str, 300, 2, 40, red, false).
	ptp(str).
}

Function verbose {
	parameter str.
	hudtext(str, 15, 2, 40, green, false).
}

Function verboselong {
	parameter str.
	hudtext(str, 45, 2, 40, green, false).
}

Function RadToDeg {
	parameter radians.
	return radians * 180 / PI.
}

Function DegToRad {
	parameter degrees.
	return degrees * PI / 180.
}

Function SinH {
	parameter x.
	set x to DegToRad(x).
	return (BaseE ^ x - BaseE ^ (-x)) / 2.
}

Function CosH {
	parameter x.
	set x to DegToRad(x).
	return (BaseE ^ x + BaseE ^ (-x)) / 2.
}

Function ArCosH {
	parameter x.
	return RadToDeg(ln(x + sqrt((x ^ 2) - 1))).
}

Function ArTanH {
	parameter x.
	return RadToDeg(ln((1 + x) / (1 - x)) / 2).
}

Function GetPolarDistance {
	parameter r1, theta1, r2, theta2.
	return sqrt(r1 ^ 2 + r2 ^ 2 - 2 * r1 * r2 * cos(theta2 - theta1)).
}

// return a maneuver node to
Function getNode {
	parameter v1, v2, rB, ut.
	local v_delta is v2 - v1.
	//verbose("v_delta: " + v_delta).
	// print v_delta:mag.
	local v1P is v1:normalized. // normalized prograde vector
	// print rB.
	// print v1.
	local v1N is vcrs(v1P, rB):normalized.// normalized normal vector
	local v1R is vcrs(v1P, v1N). // normalized radial vector
	local prograde is vdot(v1P, v_delta).
	local radial is -vdot(v1R, v_delta).
	local normal is vdot(v1N, v_delta).
	return node(ut, radial, normal, prograde).
}

// return a maneuver node to
Function getNodeDv {
	parameter v1, v_delta, rB, ut.
	local v1P is v1:normalized. // normalized prograde vector
	local v1N is vcrs(v1P, rB):normalized.// normalized normal vector
	local v1R is vcrs(v1P, v1N). // normalized radial vector
	local prograde is vdot(v1P, v_delta).
	local radial is -vdot(v1R, v_delta).
	local normal is vdot(v1N, v_delta).
	return node(ut, radial, normal, prograde).
}

Function getTAnom {
	parameter eccentricity, ea.
	set ea to clamp180(ea).
	if eccentricity > 1 {
		local ta is arccos((CosH(ea) - eccentricity) / (1 - eccentricity * CosH(ea))).
		if (ea < 0) set ta to 360 - ta.
		return ta.
	}
	local ta is 2 * arctan(((1 + eccentricity) / (1 - eccentricity)) ^ 0.5 * tan(ea / 2)).
	return clamp360(ta).
}

Function getEAnom {
	parameter eccentricity, trueanomaly.
	if eccentricity > 1 {
		set trueanomaly to clamp180(trueanomaly).
		local E is ArCosH((eccentricity + cos(trueanomaly)) / (1 + eccentricity * cos(trueanomaly))).
		if (trueanomaly < 180) set E to 360 - E.
		return E.
	}
	local E is arccos((eccentricity + cos(trueanomaly)) / (1 + eccentricity * cos(trueanomaly))).
	if (clamp360(trueanomaly) > 180) set E to 360 - E.
	return E.
}

Function approxEAnom {
	parameter ecc, ma.
	local done is false.
	local ea_n is ma.
	local ea_n1 is 0.
	local itt is 0.
	until done = true {
		if ecc > 1 {
			set ea_n1 to ea_n + (ma + ea_n - RadToDeg(ecc * SinH(ea_n))/RadToDeg(ecc * CosH(ea_n) - 1)).
		}
		else {
			set ea_n1 to ea_n + (ma - ea_n + RadToDeg(ecc * sin(ea_n))/RadToDeg(1 - ecc * cos(ea_n))).
		}
		set ea_n1 to ea_n + (ma - ea_n + RadToDeg(ecc * sin(ea_n))/RadToDeg(1 - ecc * cos(ea_n))).
		if abs(ea_n/ea_n1) > 0.9999 { set done to true. }
		else {
			set itt to itt + 1.
			if itt > 100 {
				set done to true.
				warn("approxEAnom: max iterations reached, ratio: " + round(abs(ea_n/ea_n1), 5)).
			}
		}
		set ea_n to ea_n1.
	}
	return ea_n.
}

Function getMAnom {
	parameter eccentricity, EAnom.
	if eccentricity > 1 {
		return RadToDeg(eccentricity * SinH(EAnom)) - EAnom.
	}
	local ma is EAnom - RadToDeg(eccentricity * sin(EAnom)).
	return ma.
}

Function getEtaTrueAnom {
	parameter trueanomaly.
	return getEtaTrueAnomOrbitable(trueanomaly, ship).
}

Function getEtaTrueAnomOrbitable {
	parameter ta, ves.
	// if (ta < ves:obt:trueanomaly) set ta to ta + 360.
	local ecc is ves:obt:eccentricity.
	local mu is ves:body:mu.
	local a is ves:obt:semimajoraxis.
	local ta0 is ves:obt:trueanomaly.
	if (ecc > 1) {
		set ta0 to clamp180(ta0).
		//local r is (ship:position - ship:body:position):mag.
		set ta to clamp180(ta).
		local F0 is ArCosH((ecc + cos(ta0)) / (1 + ecc * cos(ta0))).
		//local F0 is ArTanH(sqrt((e - 1) / (e + 1)) * tan(ta0 / 2)).
		if ta0 < 0 set F0 to -F0.
		local Fn is ArCosH((ecc + cos(ta)) / (1 + ecc * cos(ta))).
		//local Fn is ArTanH(sqrt((e - 1) / (e + 1)) * tan(ta / 2)).
		if ta < 0 set Fn to -Fn.
		local M0 is RadToDeg(ecc * SinH(F0)) - F0.
		local Mn is RadToDeg(ecc * SinH(Fn)) - Fn.
		local t0 is M0 / RadToDeg(sqrt(mu / abs(a^3))).
		local tn is Mn / RadToDeg(sqrt(mu / abs(a^3))).

		return tn - t0.
	}
	set ta to clamp360(ta).
	local En is getEAnom(ecc, ta).
	local E0 is getEAnom(ecc, ta0).
	local Mn is getMAnom(ecc, En).
	local M0 is getMAnom(ecc, E0).
	local dM is Mn - M0.
	local eta is dM/RadToDeg(sqrt(mu/(abs(a^3)))).
	until eta > 0 {
		set eta to eta + ves:obt:period.
	}
	until eta < ves:obt:period {
		set eta to eta - ves:obt:period.
	}
	return eta.
}

Function getTAFromOrbitableUt {
	parameter ves, ut.
	local t1 is time:seconds.
	local t2 is ut.
	local dt is t2 - t1.
	return getTAFromOrbitableEta(ves, dt).
}

Function getTAFromOrbitableEta {
	parameter ves, dt.
	local ecc is ves:orbit:eccentricity.
	local period is ves:orbit:period.
	local ta1 is ves:orbit:trueanomaly.
	local ea1 is getEAnom(ecc, ta1).
	local ma1 is getMAnom(ecc, ea1).
	local ma2 is clamp360(ma1 + dt * 360 / period).
	local ea2 is approxEAnom(ecc, ma2).
	local ta2 is getTAnom(ecc, ea2).
	return clamp360(ta2).
}

Function getUniversalLon {
	parameter ves.
	return clamp360(ves:orbit:lan + ves:orbit:argumentofperiapsis + ves:orbit:trueanomaly).
}

Function getUniversalLonFromTA {
	parameter ves, ta.
	return clamp360(ves:orbit:lan + ves:orbit:argumentofperiapsis + ta).
}

function LambertSolver {
	parameter r0, r1, ta0, ta1, dt, mu.
	local debug is false.
	// based on http://ccar.colorado.edu/asen5050/ASEN5050/Lectures_files/lecture16.pdf
	// state 0: initial orbit at point of transfer burn
	// state 0b: transfer orbit at point of transfer burn
	// state 1: transfer orbit at destination point
	if debug {
		alert("r0:  " + r0).
		alert("r1:  " + r1).
		alert("ta0: " + ta0).
		alert("ta1: " + ta1).
		alert("dt:  " + dt).
		alert("mu:  " + mu).
	}
	local dta is clamp360(ta1 - ta0).
	if abs(dta - 180) < 0.1 {
		// this calculation is undefined if dta = 180 degrees, guard against that condition
		if (dta - 180 > 0) {
			set dta to 180.1.
		}
		else{
			set dta to 179.9.
		}
	}
	local tm is 1.
	if dta > 180 set tm to -1.
	//local cosdta is cos(dta).
	//alert("cos: " + cosdta).
	//local sindta is sin(dta).
	local a is tm * sqrt(r0 * r1 * (1 + cos(dta))).
	if debug {
		alert("a:   " + a).
		alert("dta: " + dta).
		alert("tm:  " + tm).
	}
	if a = 0 {
		error("Cannot solve this orbit").
		set x to 1/0.
	}
	local dtn is 0. // delta t
	local dean is dta / 2. // delta E
	local psin is dean ^ 2. // delta E squared
	//local psiup is (dean * 1.5) ^ 2
	local psiup is RadToDeg(RadToDeg(4 * pi ^ 2)).
	//local psiup is psin * 1.25^2.
	//local psilow is -4 * pi.
	local psilow is 0.
	//local psilow is (dean * 0.5) ^ 2
	local count is 0.
	local chin is 0.
	local yn is -1.
	until abs(dtn - dt) < 0.0001 or count >= 200 {
		if count > 0 {
			if (dtn <= dt) {
				set psilow to psin.
				//set psilow to (psilow + psin) / 2.
				//alert("psi low:  " + psilow).
			}
			else {
				set psiup to psin.
				//set psiup to (psihigh + psin) / 2.
				//alert("psi up:   " + psiup).
			}
			set psin to (psiup + psilow) / 2.
			set dean to sqrt(psin).
		}
		local dean_rad is DegToRad(dean).
		local psi_rad is dean_rad ^ 2.
		//alert("psi: " + psin).
		//alert("dea: " + dean_rad).
		//alert("psi: " + psi_rad).
		local c2 is (1 - cos(dean)) / psi_rad.
		//alert("c2:  " + c2).
		//local c3 is (DegToRad(dean) - sin(psin)) / DegToRad(psin).
		local c3 is (dean_rad - sin(dean)) / dean_rad ^ 3.
		//alert("c3:  " + c3).
		set yn to r0 + r1 + a * (psi_rad * c3 - 1) / sqrt(c2).
		//alert("yn:  " + yn).
		if a > 0 and yn < 0 {
			error("adjust psilow until yn > 0.").
			// adjust psilow until yn > 0.
			until yn > 0 or count > 30 {
				set psilow to (psiup + psilow) / 2.
				set psin to (psiup + psilow) / 2.
				set dean_rad to DegToRad(dean_rad).
				set psi_rad to DegToRad(dean_rad) ^ 2.
				set c2 to (1 - cos(dean)) / psi_rad.
				set c3 to (dean_rad - sin(dean)) / dean_rad ^ 3.
				set yn to r0 + r1 + a * (psi_rad * c3 - 1) / sqrt(c2).
				//alert("yn:  " + yn).
				set count to count + 1.
			}
		}
		set chin to sqrt(yn / c2).
		set dtn to (c3 * chin ^ 3 + a * sqrt(yn)) / sqrt(mu).
		//alert("dtn: " + dtn).
		set count to count + 1.
		//wait 0.
	}
	local sma0b is (chin / DegToRad(dean)) ^ 2.
	if debug {
		alert("solved in " + count + " iterations").
		//alert("cnt: " + count).
		//alert("psi: " + psin).
		alert("yn:  " + yn).
		alert("dtn: " + dtn).
		alert("sma: " + sma0b).
	}
	local ecc is sqrt(1 - r0 * r1 / sma0b / yn * (1 - cos(dta))).
	local f is 1 - yn/r0.
	local g is a * sqrt(yn/mu).
	local gprime is 1 - yn/r1.
	return list(sma0b, ecc, yn, a, dean, f, g, gprime).
}

function getClosestApproach {
	local window to max(ship:obt:period, tgt:obt:period).
	local centerUT is time:seconds + window / 2.
	alert("centerUT: " + round(centerUT)).
	local closestDistance is 10^50.
	local result is getClosestApproachHelper(centerUT, window, 180).
	set centerUT to result[0].
	set closestDistance to result[1].
	set window to result[2] * 3.
	//verboselong("Closest distance 1: " + result[1]).
	set result to getClosestApproachHelper(centerUT, window, 180).
	set centerUT to result[0].
	set closestDistance to result[1].
	set window to result[2] * 3.
	//verboselong("Closest distance 2: " + closestDistance).
	set result to getClosestApproachHelper(centerUT, window, 90).
	set centerUT to result[0].
	set closestDistance to result[1].
	set window to result[2].
	//alert("Closest distance 3: " + closestDistance).
	return result.
}

function getClosestApproachHelper {
	parameter centerUT, windowDT, stepCount.
	//clearvecdraws().
	//global vecdraws is list().
	local period to max(ship:obt:period, tgt:obt:period).
	local timestep to windowDT / stepCount.
	local closestDistance to 10^50.
	local closestTime to -1.
	local maxdt to stepCount / 2 * timestep.
	local mindt to -maxdt.
	from { local dt is mindt. } until dt > maxdt step { set dt to dt + timestep. } do {
		local sampleTime is centerUT + dt.
		local posOrigin to positionat(ship, sampleTime).
		local posDestination to positionat(tgt, sampleTime).
		local orbitDestination to orbitat(ship, sampleTime).
		if (orbitDestination:body <> ship:body) {
			local tmpBody is orbitDestination:body.
			set posOrigin to posOrigin - tmpBody:position + positionat(tmpBody, sampleTime).
		}
		local distance to (posDestination - posOrigin):mag.
		if distance < closestDistance {
			set closestDistance to distance.
			set closestTime to centerUT + dt.
			//vecdraws:add(vecdraw(v(0,0,0), posDestination, green, round(sampleTime), 1, true)).
			//vecdraws:add(vecdraw(posOrigin, posDestination - posOrigin, purple, "", 1, true)).
		}
		//else {
			//vecdraws:add(vecdraw(v(0,0,0), posDestination, red, round(sampleTime), 1, true)).
			//vecdraws:add(vecdraw(v(0,0,0), posOrigin, yellow, "", 1, true)).
			//vecdraws:add(vecdraw(posOrigin, posDestination - posOrigin, yellow, "", 1, true)).
		//}
	}
	return list(closestTime, closestDistance, timestep).
}

function GetLambertInterceptNode {
	parameter origin, destination, ut, dt, offsetVec.
  local tgt is target.
	local burntime is ut.
	local closestTime is ut + dt.
	local pos0 is positionat(origin, burntime).
	local pos1 is positionat(tgt, closestTime) + offsetVec.
	local vd_pos0 is vecdraw(v(0,0,0), pos0, red, "", 1, true).
	local vd_pos1 is vecdraw(v(0,0,0), pos1, blue, "", 1, true).
	//wait until abort.
	local posB is ship:body:position.
	local r0 is pos0 - posB.
	local r1 is pos1 - posB.
	local dta is vang(r0, r1).
	if (vdot(vcrs(r0, r1), v(0,1,0)) > 0) set dta to clamp360(-dta).
	local solution to LambertSolver(r0:mag, r1:mag, 0, dta, dt, ship:body:mu).
	local f is solution[5].
	local g is solution[6].
	local gprime is solution[7].
	local vburn is (r1 - f * r0) * (1 / g).
	local v0 is velocityat(ship, burntime):orbit.
	local dv is vburn - v0.
	local nd is getNodeDV(v0, vburn - v0, r0, burntime).
	add nd.
	return nd.
}
// http://www.amostech.com/TechnicalPapers/2011/Poster/DER.pdf lambert2
