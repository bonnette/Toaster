# Toaster
A project that uses an ESP32 (Arduino) to simulate a bluetooth connected "Toaster"<br/>
The iPhone connects to the "Toaster" and follows the toasting process by changing the icons on the phone.<br/>
This project allowed me to understand the bluetooth communications between an Arduino and iPhone as well as explore iPhone responses to the activities.<br/><br/>
# Activity flow
The phone begins with a "Not ready" icon.<br/>
When the toaster connects (using Bluetooth) to the iPhone the iPhone responds with a "Ready" icon.<br/>
When the "Toast" button on the phone is pressed. A message is sent to the Arduino to begin toasting the bread.<br/>
The arduino turns on an LED to indicate that "Toasting" has begun and a message is sent back to the phone to indicate that "Toasting" has begun.<br/>
The phone reponds by changing the Icon to a "Toasting" icon and greys out the "Toasting button"<br/>
When the  Arduino has completed its toasting process (20 second time out). The Arduino sends a "Toasting complete" message to the iPhone.<br/>
The phone recieves the "complete" message and changes the icon to a "Toasted" icon.<br/>
Ten seconds later the Arduino sends a "Ready to toast" message to the phone and the phone responds with a "Ready" icon and un-greys the "Toast" button.<br/>
