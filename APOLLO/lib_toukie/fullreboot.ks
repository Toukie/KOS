list files in w.
for i in w {
  if i:name:contains("lib"){
    deletepath(i).
  }
}
clearscreen.
reboot.

print "read fullreboot".
