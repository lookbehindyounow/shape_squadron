# Shape Squadron
### flying triangle dogfight game
If you just wanna play the game you can [download a dmg/exe](https://lookbehindyounow.itch.io/shape-squadron)\
To edit you will need the [Godot 4 engine](https://godotengine.org/download) - clone this repo, open the launcher, click the scan button, navigate to the shape_squadron folder & click project.godot, once the game is in your project list, open it & click the play button in the top right.

### Controls
Some of the keyboard controls are quite odd, this is becuase most of the testing has been done on a mac without a mouse.
Controls can be changed in project > project settings > input map (you can't change them in the executable versions).\
If Godot is not correctly recognising your gamepad's buttons, you could try creating a new mapping for your gamepad with [this](https://generalarcade.com/gamepadtool/), it worked for me
Action|Keyboard|Gamepad
-|-|-
accelerate|space|right trigger
decelerate|cmd|left trigger
roll left|a|left stick left
roll right|d|left stick right
pitch up|s|left stick down
pitch down|w|left stick up
yaw left|left arrow|d-pad left
yaw right|right arrow|d-pad right
slight pitch up|up arrow|d-pad up
slight pitch down|down arrow|d-pad down
shoot|comma|A (xbox) × (playstation)
missile (hold for missile camera)|period| B (xbox) ○ (playstation)
cycle through enemy cameras|c|right stick click
toggle freeze all enemies|v|left bumper
restart|enter|start/option/menu

### Project goals
This project was my final project for the CodeClan software development course, the initial idea was to make something that felt like Ace Combat X for the PSP.
I haven't updated the game since the end of the project other than to reorganise files but I have plans to add new features such as:
- better plane models (although I'll probably keep a low poly setting available cause I like the triangles)
- landscapes, ocean, better sky & better ground obstacles (will require more enemy behaviour programming for them to avoid obstacles)
- missions
- take off & landing, maybe mid-air refueling as well
- leaderboards hosted online, if I have missions I could also have an arcade mode with waves of enemies
- non-copyrighted music
- ray cast obstacle detection
- gravity & stalling
- customisable controls from a menu within the game
- easy way to set up scenarios for testing enemy behaviour (unit testing needed as well)
