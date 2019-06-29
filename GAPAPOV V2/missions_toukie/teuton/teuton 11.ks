// NOT BEING ABLE TO LOAD STUFF IS A STORAGE SPACE ISSUE, GET A BETTER KOS PROCESSOR

TX_lib_dependencies["AllDepencies"](scriptpath()).

local NewNode is Node(time:seconds + eta:apoapsis, 0, 0, 547.5).
add NewNode.
TX_lib_calculations["ClosestApproachFinder"](Mun).

// good nuf
// real closest:   8200 km
// found closest: 10650 km
