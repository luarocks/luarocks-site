
if f = io.open("revision")
  with f\read "*a"
    f\close!
else
  "No Revision Info"
