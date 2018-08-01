Demonstration:
[![IMAGE ALT TEXT HERE](http://img.youtube.com/vi/YOUTUBE_VIDEO_ID_HERE/0.jpg)](http://www.youtube.com/watch?v=YOUTUBE_VIDEO_ID_HERE)

To run GAPAPOV you will first need to install KOS:

Then drag the /toukie/Script/ folder into your KSP install's /Ships/ folder and merge the folders if needed.

When IN ORBIT type the following to start the program, press the ENTER key to finish the sentence:

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
The best thing to do in such a situation is it restart the program with the steps mentioned above.
