# Decouple 1.0
* Requires [UnitXP SP3](https://github.com/allfoxwy/UnitXP_SP3/)  
The easiest way to use it is to add to your [VanillaFixes](https://github.com/hannesmann/vanillafixes) dll load list.  
___

The 1.12 client runs your addon update loops every frame draw, this addon automatically decouples these updates from the framerate to a set update rate of 60 fps on another thread.  
Certain addons which need updating much less often are special cased to update even slower as well.  

It may improve your framerate and reduce stutter in game, or it may not, vanilla client seems to perform very different for each person.  

Related efficiency addons:
* https://github.com/MarcelineVQ/GentleGC - Run garbage collection more often, without new allocation, to trade large gc pauses for more frequent smaller ones.  
* For some clients the video engine change in VanillaFixes can lower your framerate, rename `d3d9.dll` to test if this includes yours.  

___
* Made by and for Weird Vibes of Turtle Wow  
