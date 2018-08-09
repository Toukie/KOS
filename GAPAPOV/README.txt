To run GAPAPOV you will first need to install KOS: https://ksp-kos.github.io/KOS/downloads_links.html#obtain

Then drag the /Script/ folder from the zip file into your KSP install's /Ships/ folder and merge the folders if needed.

To open the KOS terminal right click the KOS processor and activate it. When IN ORBIT type the following to start the program, press the ENTER key to finish the sentence:

copypath("0:/boot/bootup_toukie", "").

runpath(bootup_toukie).


IMPORTANT TECHNICAL CONFIGURATIONS:

Only use this scrip when in a stable orbit (a high orbit is advised because you'll be able to use a higher timewarp).

Increase the amount of patches KSP will show to >4. If this doesn't happen some calculations can't be run.
To increase patches open KSP and go to:
  - Settings
  - Graphics
  - Conic Patch Limit

GAPAPOV calculates how much Dv to burn using its calculated Dv value.
This value changes when infinite fuel is used or if the amount of fuel gets edited while burning.
So to prevent GAPAPOV from crashing don't change fuel mid burn.

GAPAPOV can't accurately calculate the Dv if asparagus staging is being used.
Be cautious when using asparagus staging.

Accidental moon encounters have a big chance of messing stuff up.
