Function GetMaxTimeWarp {
  set kuniverse:timewarp:warp to 10.
  local MaxWarp is kuniverse:timewarp:warp.
  set kuniverse:timewarp:warp to 0.
  return MaxWarp.
}

print GetMaxTimeWarp().
