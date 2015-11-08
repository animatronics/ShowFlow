#Show-Flow: A Software Tool for Creating Non-Linear Animatronic Puppet Shows

##Introduction
Show-Flow is a tool that lets you describe a show as a state machine: with the scenes as states and events that determine which is the next state/scene. In every scene, the user can include several audio files (either recorded within the software, or dragged in) and actuator animation tracks to control motion. The transition between scenes can be triggered by three types of events: timers, sensors, and variables reaching a trigger value. In this project, we also hope to inspire learning state machines and how to use them in code, so we provide code generated from the show schematics and hope it starts an educational activity.

The demo show created with Show-Flow for UIST is available at https://youtu.be/3Y2i5UnYe6I

##How to Use
You can create a new project. Show-Flow will create a folder in a specified place. The folder content is: "<project-name>.json" (file used to load the project), "data" folder with all audio tracks inside, if you choose the Code tab, you will also create the "<project-name>.pde" and "actions.pde" files. If you have Arduino boards in your project, each one will have a "name+id" folder created with a "name+id.ino" file. You can also save your project and load a saved project (using the .json file).

You can add new scene in the Overview tab with the "+" button. You can connect scenes by dragging a link stub from one scene onto another. You can reconnect existing links by dragging their beginning or end. Every scene has visual indicators for text, audio tracks, and motion tracks that are grayed out when they have not been used yet.
<img src="http://nurki.net/Misc/connect.png" alt="connecting links" width=400  /> 
Clicking on a link will call a pop-up. You can erase that link, add a scene in the middle of it, or add one of the three events. You can add several events to the same link if you want it to trigger only when all the conditions are met. A link is grayed out until it has an event associated with it.

<img src="http://nurki.net/Misc/setEvent.png" alt="connecting links" width=400  /> 
In the scene tab, you can change the name of the scene and add text (probably the script for the scene). You can record a track using the record button, or drag an existing audio file into the scene tab. Use the new animation button next to the record button to add an animation track. When the small toggle button on an animation track is on, you may add keyframes to the animation: the top of the track maps to the maximum value of an associated actuator, and the bottom to the minimum values (those values are set per actuator in the resource tab). Keyframes can be dragged to edit their position, or deleted with the "delete" button (you can also selected a section of the track and delete all keyframes in it). In the scene tab, you can also switch to next or previous scene, change the zoom level, and change the color associated with the scene. The play button will playback the scene you are editing.
A section on the bottom left will show all the variables (if any) declared in the project. You may set an interaction for every scene and variable (or leave it as "none".)
<img src="http://nurki.net/Misc/scenetab.png" alt="connecting links" width=400  /> 

The resource tab aggregates all the resources in the project, and lets you create the hardware connections by making new controllers or actuators. Every resource will have different possible settings. For a controller, for example, you will select if it is a Pololu or Arduino and choose its name from a list. For an actuator, you will set a pin number whether it is analog or digital, its max and min values, and the controller it will connect to. You can associate some resources (like a controller and actuator) by dragging one onto the other. If your hardware is not currently connected, a grey disconnected symbol appears on the bottom right of the icon. The Sensor resource can show the current values sent by the controller if you click the Play button.
<img src="http://nurki.net/Misc/resourcetab.png" alt="connecting links" width=400  /> 

When you click on the Code tab, new processing code is generated from the schematics in Overview, and, if applicable, new Arduino code is created based on the sensors and actuators connected to controller in Resources. These files are written in the project folder. The processing code can run in a stand-alone way- playing the show without the visual interface. 
<img src="http://nurki.net/Misc/codetab.png" alt="connecting links" width=400  /> 


##Author
This code was written for UIST 2015 Student Innovation Contest by the team Webmaster of Puppets, A.K.A Nurit Kirshenbaum from the University of Hawaii at Manoa (nuritk [at] hawaii.edu).
