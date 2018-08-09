declare function ListScienceModules {
    declare global scienceModules to list().
    declare local partList to ship:parts.

    for thePart in partList { // loop through all of the parts
        declare local moduleList to thePart:modules.
        for theModule in moduleList { // loop through all of the modules of this part
            if theModule:contains("science"){
            declare local actionList to thePart:getmodule(theModule):allactions.
            for theAction in actionList { // loop through all of the actions of this module
                if theAction:contains("data") { // name of the action contains the word 'data', so it's a science module
                    scienceModules:add(thePart:getmodule(theModule)). // add it to the list
                    break. // no need to continue looking at this module's actions
                }
              }
            }
        }
    }
    return scienceModules.
}

// GetSpecifiedResource takes one parameter, a search term, and returns the resource with that search term
declare function GetSpecifiedResource {
    declare parameter searchTerm.

    declare local allResources to ship:resources.
    declare local theResult to "".

    for theResource in allResources {
        if theResource:name = searchTerm {
            set theResult to theResource.
            break.
        }
    }
    return theResult.
}

// Given some science data to transmit,
// - verify that sufficient electrical capacity exists to attempt to transmit
// - wait until sufficient charge before transmitting
declare function WaitForCharge {
    declare parameter scienceData.

    // This value are from http://wiki.kerbalspaceprogram.com/wiki/Antenna
    // for the Communotron 16 antenna.
    // It'd be better if I could search for the antenna and get these values,
    // but they don't appear to be there
    declare local electricalPerData to 6.

    declare local electricalResource to GetSpecifiedResource("ElectricCharge").
    declare local chargeMargin to 1.05. // Want to have not just enough, but a 5% margin
    declare local canTransmit to true.
    declare local neededCharge to scienceData:dataamount * electricalPerData * chargeMargin.

    if electricalResource:capacity > neededCharge {
        if (electricalResource:amount < neededCharge) {
            // current electrical capacity is insufficient, so wait and display messages
            until electricalResource:amount > neededCharge {
                print "Waiting for sufficient electrical charge" at (1,2).
                print "Need: " + round(neededCharge, 1) + "  Have: " + round(electricalResource:amount, 1) + "   " at (1,3).
                wait 1.
            }
        }
    } else {
        print "Insufficient electrical capacity to attempt transmission" at (1,2).
        set canTransmit to false.
    }
    return canTransmit.
}

declare function TransmitScience {
    declare parameter scienceModule.

    // This value is from http://wiki.kerbalspaceprogram.com/wiki/Antenna
    // for the Communotron 16 antenna.
    // It'd be better if I could search for the antenna and get these values,
    // but they don't appear to be there
    declare local timePerData to 10/3.
    declare local transmissionMargin to 1.05. // Let's also put a 5% margin on the transmission time

    // Figure out how long it'll take to transmit data.
    // Add 1 second for margin

    declare local transmissionTime to scienceModule:data[0]:dataamount / timePerData * transmissionMargin.

    print "Transmitting data                                   " at (1,2).
    scienceModule:transmit().

    // Display transmission countdown timer
    declare local startTime to time:seconds.
    until time:seconds > startTime + transmissionTime {
        print round(startTime + transmissionTime - time:seconds,1) + " seconds to go                                " at (1,3).
        wait 0.2.
    }
}

// Function to run all re-runnable science experiments and transmit the results
declare function PerformScienceExperiments {
    declare local scienceModules to ListScienceModules().

    clearscreen.
    // start by looking for existing science from previous experiments; transmit if found
    for theModule in scienceModules {
        if theModule:hasdata {
            print "Existing data found in " + theModule:part:title at (1,1).
            if WaitForCharge(theModule:data[0]) {
                TransmitScience(theModule).
            }
        }
    }

    // Now, loop through the operable, re-runnable experiments, running them and transmitting data back
    for theModule in scienceModules {
        clearscreen.
        set ForcequitTime to time:seconds + 10.
        print "Working with: " + theModule:part:title at (1,1).
        wait 1.
        // Only perform operable, re-runnable experiments on modules that don't have data
        if (not theModule:inoperable) and (theModule:rerunnable) and (not theModule:hasdata) {
            print "Collecting data                                               " at (1,2).
            theModule:deploy(). // collect science, waiting for results to be ready
            wait until theModule:hasdata or Time:seconds > ForcequitTime.
            if Time:seconds > ForcequitTime {
              print "Force quit experiment".

            } else {
            if WaitForCharge(theModule:data[0]) {
                TransmitScience(theModule).
            }
          }
        }
        wait 1.
    }
    clearscreen.
    print "All data collection and transmission complete".
}

print "read lib_science".
