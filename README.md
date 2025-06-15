# Indy’s Trains

A script to add customizable cyber metro trains (from BN3/EXE3) to Open Net Battle servers. 

![train-preview](https://github.com/user-attachments/assets/1282c0e3-485a-409b-83c3-67c8e699e623)

<h3>How does it work?</h3>

> This script is plug-n-play. Once you copy the required scripts and assets to your server (see below) everything else is configured within the Tiled map editor for your server area. Additionally, you can install the Tiled extension which will make adding them to your map even easier. 

### Want to try it out? 

> This repository is a complete test server you can spin up that includes configured examples for both types of trains and the conductor. It will show you how they should be configured and how they function in-game without having to do the setup yourself. 

### How do I install this on my ONB server? 

> 1. Download the repository. 
> 2. Copy `/assets/indy-trains/` to your server’s asset folder. 
> 3. Copy `/scripts/indy-trains/` to your server’s script folder. 
> 4. Copy `indys-trains-tiled.js` to your Tiled extension folder.
> <br> (in Tiled go to Settings, select Plugins, then click "Open..." below Extensions).

Note: The Tiled extension is only compatible with Tiled 1.9 and newer. If you're using an older version upgrade (1.11.2 works fine with ONB) or configure trains manually. You will need to look at the demo server configurations to underatand the setup because the documentation here is written based on the extension. 

### What's included in this script? 

> This script adds three new object types: Cargo Trains, Passenger Trains, and Conductors. Cargo Trains run along a straight path on a loop and do not have any interactions (they are purely aesthetics). Passenger Trains function exactly like the cyber metro from BN3/EXE3 where you talk to a Mr. Prog (Conductor) who summons a train and the player is transported to another area. Conductors spawn the Mr. Prog and should be placed wherever you want players to request a Passenger Train. <br><br>All of the necessary assets (sprites, animations, and sound effects) are included with the script. 

&nbsp; <br>
### How do I add a Cargo Train?

Cargo Trains run along a straight path on a loop and do not have any interactions (they are purely aesthetic).

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Cargo Train...`
   4. Fill in the dialog box based on the information below:
> `Train Name` must be unique for the area.<br>
> `Color` changes the train's appearance.<br>
> `Speed` can be increased to make the train move faster (1 = default, 1.5 is 50% faster, 2 is 100% faster, etc.) <br>
> `Direction` select which direction the train is traveling.<br>
> `Train Z` provide the Z (layer) where the train should spawn.<br>
>  &nbsp; &nbsp; For the bottom most layer, Z equals 0 and goes up by 1 as you move upward.<br>
> `Start Point` provide a x,y tile position (hover over a tile and look in the bottom left of Tiled to see X and Y).<br>
> `End Point` provide a x,y tile position (hover over a tile and look in the bottom left of Tiled to see X and Y).<br>
> `Driver Texture` path to image file for your Driver NPC (optionaL). <br>
> `Driver Animation` path to .animation file for your Driver NPC (optional). <br>
> `Cargo Texture` (NOT IMPLEMENTED) path to image file for your cargo/passenger NPC (optional). <br>
> `Cargo Animation` (NOT IMPLEMENTED) path to .animation file for your cargo/passenger NPC (optional).

  5. Click "Add Train" (a new Point will be added to your map, you can place it anywhere). 

The dialog box is smart so if you type something that's malformed it will let you know. However, it doesn't check if your X,Y,Z positions are correct. If you need to edit them after you make your Cargo Train simply press `S` on your keyboard (selects the `Select Object` tool) and click on the Point on your map for your Cargo Train, you can then change the X,Y,Z values on the left under _Custom Properties_. 

&nbsp; <br>
### How do I add a Passenger Train?

Passenger Trains can transport players between areas within a server or to completely different servers. The receiving server does not need a train configured for the transfer to work, however, if no train on the receiving server is configured then the player will simply be dropped off at the Home Warp of the destination server. 

**Important:** Because of how tiles/objects stack in ONB, your train object and track should be four layers below your walkable area, meaning the Vertical offset for walkable area should be -48 versus the train's position. For example, if your player stands on Layer 1 (Vertical Offset 0) you need to move it to Layer 4 (Vertical Offset -48) and put the track and train on Layer 0 (Vertical Offset 0). This also means your train's Z would be 0. If this doesn't make sense take a look at the layers in default.tmx from the demo server. If you put them any closer there will be visual glitches where the train appears above your platform (instead of below). 

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Passenger Train...`
   4. Fill in the dialog box based on the information below:
> `Train Name` is how the train is identified in other areas.<br>
>  &nbsp; &nbsp; Within a single area all train names must be unique. <br>
>  &nbsp; &nbsp; However, you must use the same Train Name for all connected trains in different areas. <br>
>  &nbsp; &nbsp; For example, if your train `train1` in ACDC 1 links to a train in Sci-Lab 1, then the train in Sci-Lab 1 also needs to be `train1`. <br>
> `Color` changes the train's appearance.<br>
> `Speed` can be increased to make the train move faster (1 = default, 1.5 is 50% faster, 2 is 100% faster, etc.) <br>
> `Direction` select which direction the train is traveling.<br>
> `Train Z` provide the Z (layer) where the train should spawn.<br>
>  &nbsp; &nbsp; For the bottom most layer, Z equals 0 and goes up by 1 as you move upward.<br>
>  &nbsp; &nbsp; Your train should be at least -3 from your Platform Z or it will glitch visually.<br>
> `Platform Z` provide the Z (layer) where the conductor stands.<br>
>  &nbsp; &nbsp; For the bottom most layer, Z equals 0 and goes up by 1 as you move upward.<br>
> `Start Point` provide a x,y tile position (hover over a tile and look in the bottom left of Tiled to see X and Y).<br>
>  &nbsp; &nbsp; This is where the train spawns, it should not be visible from the walkable parts of your area.<br>
> `Stop Point` provide a x,y tile position (this is where the train picks up passengers, you may have to tweak a few times).<br>
> `End Point` provide a x,y tile position (this is where the train despawns, should not be visible walking around the area).<br>
> `Driver Texture` path to image file for your Driver NPC (optional). <br>
> `Driver Animation` path to .animation file for your Driver NPC (optional). <br>
> `Cargo Texture` path to image file for your cargo/passenger NPC (optional). <br>
> `Cargo Animation` path to .animation file for your cargo/passenger NPC (optional).

5. You need to add a Conductor so the player can choose a destination and summon the Passenger Train (see below). 

Remember, the dialog box is smart so if you type something that's malformed it will let you know. However, it doesn't check if your X,Y,Z positions are correct. If you need to edit them after you make your Passenger Train simply press `S` on your keyboard (selects the `Select Object` tool) and click on the Point on your map for your Passenger Train, you can then change the X,Y,Z values on the left under _Custom Properties_. 

&nbsp; <br>
### How do I add a Conductor?

The conductor object will spawn an Conductor Prog when your server boots. When players interact with this NPC a menu will appear allowing players to select a destination. You will configure the destination options within Conductor object as explained below.

> Important: Where you place your conductor will dictate where the NPC spawns, so once you add it position it accordingly. It should always be next to the _Stop Position_ for your train. 

   1. Open your map in Tiled.
   2. Select an Object Layer on your map. 
   3. Open the `File` menu, click `New` and select `Add Train Conductor...`
   4. Fill in the dialog box based on the information below:
> `Conductor Name` must be unique for the area.<br>
> `Associated Train Name` provide the name of the train this Conductor controls.<br>
> `Texture` path to image file for your Conductor NPC (optional).<br>
> `Animation` path to .animation file for your Conductor NPC (optional).<br>
> `Mug Texture` path to image file for your Conductor NPC's Mug (optional).<br>
> `Mug Animation` path to .animation file for your Conductor NPC's Mug (optional).<br>
> `Destination #1` if you are transferring to another area use to map's tmx name without the suffix.<br>
> &nbsp; &nbsp; For example, if you want to go to `acdc2.tmx` enter `acdc2`<br>
> &nbsp; &nbsp; For server transfers you need to enter `IP:port,area,train_name`.<br>
> &nbsp; &nbsp; So if you're tranferring to 912.23.55.221:8765 and the area is acdc3.tmx and the recieving train name is mytrain then<br>
> &nbsp; &nbsp; you would enter `912.23.55.221:8765,acdc3,mytrain`. You will need to coordinate with the other server's owner to get the values.<br>
> `Destination #1 Label` enter a value for what you want to appear in the menu selection (if going to acdc2.tmx you would want the label to be `ACDC 2`).<br>
> `Destination #1 Type` make a selection based on what type of transfer is occuring. 
5. Click `Add Conductor` and be sure to position it as the position dictates where it spawns.

If you want to add a second destination click `Add Another Destination` and fill out the fields as before. If you add too many destinations simply leave the extras blank.

&nbsp; <br>
### Can I make a one-way Passenger Train?

Yes, simple do not add a Conductor on the other end. Once the player arrives at the destination there won't be an NPC to use to go back to where they started. 

&nbsp; <br>
### Can each Conductor have different destinations?

Yes, each conductor is completely independent and can have a unique list of destinations. For example, let's say you have a Conductor in ACDC 1, SciLab 1, and Yoka Square. You can make the Conductor in ACDC have SciLab 1 and Yoka Square as destinations, but the Yoka Square conductor can have just SciLab 1 as a destination. 

<!--
&nbsp; <br>
### Can I add extra non-destination rows to the Conductor menu?

Yes, if you want to add a row of text that doesn't send someone to a destination make the destination `cancel` and use the destination label as your textblock. This will close the menu if they select it and not activate a train. 
-->
&nbsp; <br>
### Credits

Coding - Indiana<br>
Cyber Metro Sprite - Indiana<br>
Conductor Prog Sprite - CyanMan.EXE<br>
Conductor Prog Mug - D3str0y3d<br>
Train Sound Effects - DJRezzed/Enzan<br>
