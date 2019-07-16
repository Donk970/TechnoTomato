# TechnoTomato
## The Outdoor Aeroponic Tomato Growing System
TechnoTomato is a relatively large, complex, aeroponic project aimed at growing tomatoes aeroponically in an outdoor garden.  As such there are a number of challenges that had to be addressed. 

1. Outdoor environment is unpredictable.

   In a controlled indoor environment where you have predictable temperature, humidity and light you can use a simple system that has a fixed timing for spray cycles.  In an outdoor system where temperatures can range from mid fifties at night to over a hundred ℉ during the day and light can range from bright direct sun on a cloudless day to overcast and raining you need a much better system for controlling spray timing.
2. A whole bunch of different types of tomato plants that have unique needs

   I only have Jersey Devil and Brandywine tomatoes in the system now but there are many dozens of tomato strains.  Jersey Devil and Brandywine have much different leafs; the Jersey Devil has a thin whispy leaf while the Brandywine has a thicker potato leaf.  These two plants handle water stress differently; one wilts much more quickly than the other.  
3. Logging to a ThingSpeak channel while doing everything else
   
   In amongst reading sensors for three or four plants, controlling the valves for those plants, reading ambient air temperature and humidity and root temperature we are also sending data for each plant to a ThingSpeak channel once a minute.

These challenges have led to a combination of hardware and software innovations including a spray system that is easy to replace if it gets clogged, a burried root chamber that stays cool, a more or less modular control board and fully asynchronous, object oriented, state driven Arduino sketch.
### The Spray System
The heart of TechnoTomato is the nutrient delivery system and the Arduino that controls spray timing.  Everything else is just supporting this main function.
#### The Plumbing
##### Major Parts:
| Image | Description |
| --- | --- |
| ![Pressure Pump](Documentation/Images/Plumbing/Pressure_Pump.jpg) | 100psi Aquatech pressure pump |
| ![Pressure Switch](<Documentation/Images/Plumbing/1:4" Press Fit Pressure Switch.png>) | 100psi Pressure switch for Aquatech pressure pump |
| ![Accumulator](Documentation/Images/Plumbing/Accumulator.png) | Accumulator |
| ![Filter](Documentation/Images/Plumbing/Filter.png) | Filter |
| ![Valve](<Documentation/Images/Plumbing/1:4" Press Fit Solenoid Valve.png>) | Solenoid Valve |
| ![Spray Nozzle](<Documentation/Images/Plumbing/Spray Nozzle.png>) | Spray Nozzle |
##### Other Parts: 
| Image | Description |
| --- | --- |
| ![3/8" to 1/4" reducing couple](<Documentation/Images/Plumbing/3:8" to 1:4" Press Fit Reducing Fitting.png>) | 3/8" to 1/4" reducing coupling |
| ![Elbow](<Documentation/Images/Plumbing/1:4" Press Fit Elbow.png>) | 1/4" Press Fit Elbow |
| ![Tee](<Documentation/Images/Plumbing/1:4" Press Fit Tee.png>) | 1/4" Press Fit Tee |
| ![End Cap](<Documentation/Images/Plumbing/1:4" Press End Cap.png>) | 1/4" Press Fit end cap |

#### The Controller

