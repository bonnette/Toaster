//
//  ViewController.swift
//  Toast
//
//  Created by Bear Cahill on 2/13/18.
//  Copyright © 2018 Bear Cahill. All rights reserved.
//  Modified by Larry Bonnette (12/2018) to control an led on an ESP32 (Arduino "like" device)
//

import UIKit
import CoreBluetooth

let arduinoSvc = CBUUID.init(string: "DF01") // The Arduino service
let arduinoLEDchar = CBUUID.init(string: "DF02") // This is the Rx charateristic on the Arduino. It is the Tx here on the iPhone
let arduinoLEDstate = CBUUID.init(string: "DF03") // This is the Tx charateristic on the Arduino. It is the Rx here on the iPhone
var LedSendChar: CBCharacteristic! // This is the data sent to the Arduino (for the LED on/off)
var LedReadState: CBCharacteristic! // This is the data sent to the iPhone indicating the LED on or off state
var savedPeripheral: CBPeripheral? // This is the peripheral name used to address the Adruino
var led = false // This holds the recieved (from the Arduino) led state (on or off)

// This Viewcontroller controls the "View" as well as the "Blootooth" services
class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    // This is the button on the screen that changes the state of the LED on the ESP32 (Arduino)
    @IBAction func LedStateButton(_ sender: UIButton) {
        print("Button Clicked") // sent to console for debug purposes
         // This sends an "on" signal to the Arduino
         savedPeripheral!.writeValue(Data.init(bytes: [41]), for: LedSendChar, type: CBCharacteristicWriteType.withResponse)
        
        }
    
    @IBOutlet weak var toastButton: UIButton!
    
    // This is the LED state lablel that changes depending on what is recieved from the Arduino.
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var toasterImage: UIImageView!
    
    // This looks to see if Bluetooth is powered on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            // if the power is on we look for (Scan for)  all bluetooth peripherals
            central.scanForPeripherals(withServices: nil, options: nil)
            print ("scanning...") // sent to console for debug purposes
        }
    }
    
    // If we find a periphal we look to see if it is our ESP32
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains("ESP") == true { // if it's ours it will be advertising "ESP"
            savedPeripheral = peripheral // place the peripheral in global for use in button
            print ("The peripheral Name is ", peripheral.name ?? "no name") // sent to console for debug purposes
            centralManager.stopScan() // since we found ours we stop scanning
            print ("The Advert data is ", advertisementData) // sent to console for debug purposes
            central.connect(peripheral, options: nil) // we connect to our Adruino
        }
    }
    // if we get disconnected we start the scan again
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    // If we connect to a Bluetooth device we look for services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print ("Connected to = ", peripheral.name!)// sent to console for debug purposes
        peripheral.discoverServices(nil)
        peripheral.delegate = self
    }
    
    // If a service is found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for svc in services { // we search through all services found
                if svc.uuid == arduinoSvc { // If we find our Arduino services
                    print ("We have found ", svc.uuid.uuidString, " This is our Arduino's Service") // sent to console for debug purposes
                    peripheral.discoverCharacteristics(nil, for: svc) // We look for all Charateristics on the Arduino
                }
            }
        }
    }
    // If we find charateristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let chars = service.characteristics {
            for char in chars { // we look at all charateristics
                print ("We have found ", char.uuid.uuidString) // sent to console for debug purposes
                if char.uuid == arduinoLEDchar { // we see if any of them are the send to Adruino charateristic
                    LedSendChar = char // place the charateristic in global for use in button
                 // We look for any "Notify" charateristics
                }else if char.properties.contains(CBCharacteristicProperties.notify) {
                        print("read and notify Characteristic \(char.uuid.uuidString)") // sent to console for debug purposes
                    LedReadState = char // Place read charateristic in global for use later
                    peripheral.setNotifyValue(true, for: char) // We turn on notify "listening"
                }
            }
        }
        // We are connected to toaster and we have all the info needed to begin so....
        stateLabel.text = "Ready" // We change the text on the label and change the color to blue
        stateLabel.textColor = UIColor.green
        stateLabel.textAlignment = .center
        toasterImage.image = UIImage(named: "toaster_not_toast")
    }
    
    // If we get a notification of "Data"
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            // We check to see if it is our data that is ready for us to process
            if characteristic.uuid == arduinoLEDstate {
                let s = characteristic.value![0] // Get the ascii value of the value from the BLE device
                let pz = Character(UnicodeScalar(s)) // Convert ascii to a charater
                print ("Recieved value '\(pz)' from the ESP32")
                if pz == "N" { // If the Arduino is sending us an "N" it means that the LED is "on"
                    led = true
                    print("LED is on") // sent to console for debug purposes
                    stateLabel.text = "Toasting" // We change the text in the label and change the color to red
                    stateLabel.textColor = UIColor.red
                    stateLabel.textAlignment = .center
                    toasterImage.image = UIImage(named: "toaster_toasting")
                    toastButton.isEnabled = false // Disable the toast button
                    toastButton.alpha = 0.3 // Dim the toast button
                    
                    
                }
                if pz == "X"{ // If the Arduino is sendig us an "X" it means that the LED is "off"
                    led = false
                    print("LED is off") // sent to console for debug purposes
                    stateLabel.text = "Complete" // We change the text on the label and change the color to blue
                    stateLabel.textColor = UIColor.blue
                    stateLabel.textAlignment = .center
                    toasterImage.image = UIImage(named: "toaster_toasted")
                }
                if pz == "R"{ // If the Arduino is sendig us an "R" it means that the toaster is "Ready"
                    led = false
                    print("Toaster is ready") // sent to console for debug purposes
                    stateLabel.text = "Ready" // We change the text on the label and change the color to green
                    stateLabel.textColor = UIColor.green
                    stateLabel.textAlignment = .center
                    toasterImage.image = UIImage(named: "toaster_not_toast")
                    toastButton.isEnabled = true //Enable the toast button
                    toastButton.alpha = 1 // restore the brightness to the toast button
                   
                }
            }
        
    }
    // We can do something when we write a value to the Arduino. In this case we just print to the console.
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print ("wrote value to ESP32") // sent to console for debug purposes
    }
    
    var centralManager : CBCentralManager!
    var myPeripheral : CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager.init(delegate: self, queue: nil) // initialize the Blootooth Central Manager

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

