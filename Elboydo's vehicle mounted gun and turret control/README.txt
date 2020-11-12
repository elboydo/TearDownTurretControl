ELBOYDOS MOUNTED GUN AND PLAYER CONTROLLED TURRET SCRIPT

Author : elboydo

published 11-11-2020

i dunno, i may extend this readme later. 

____________________________________________________________


To install::

Place files within create folder here to your create folder in teardown/create


To enable weapon usage, copy the hud.lua file to teardown/data/ui


IF YOU DON'T WANT TO MESS WITH YOUR HUD.LUA DUE TO OTHER MODS: 

	copy this line into the "draw()" method in hud.lua

	if UiIsMousePressed() then
		SetBool("mouse.pressed",true)
	else
		SetBool("mouse.pressed",false)
	end

	SetInt("mouse.wheel", UiGetMouseWheel()) 

if you have these methods already in your hud.lua then happy days, the mods should work fine.


FAILURE TO COPY THE HUD.LUA FILE WILL MEAN WEAPONS WON'T WORK AND ASKING WHY WEAPONS WON'T WORK DUE TO NOT DOING THIS 
		 MAY RESULT IN PANDAS HAVING THEIR FAVOURITE TOYS TAKEN AWAY FROM THEM