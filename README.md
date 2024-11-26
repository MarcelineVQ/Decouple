# Decouple 1.0
* Requires  [UnitXP SP3](https://github.com/allfoxwy/UnitXP_SP3/)
___

The 1.12 client runs your addon update loops every frame draw, this addon automatically decouples these updates from the framerate to a set update rate of 60 fps.  
Certain addons which need updating much less often are special cased to update even slower as well.  

It may improve your framerate and reduce stutter in game, or it may not, vanilla client seems to perform very different for each person.  

Related addons:
 * https://github.com/MarcelineVQ/GentleGC - Run garbage collection more often, without new allocation, to reduce overall gc pause time.

___
* Made by and for Weird Vibes of Turtle Wow  
