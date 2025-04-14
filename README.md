## iPhone app to control bench powered PEMF device

This repo houses a SwiftUI iPhone application for controlling an ESP32 driven PEMF prototype (Pulsed Electromagnetic Field therapy). A more detailed overview of the project can be found here: [PEMF-PROTOTYPE](https://github.com/ajdonich/pemf-prototype). This test app communicates via UDP packets over WIFI. The assigned ESP32 network address must be set in [IPCController.swift](https://github.com/ajdonich/EMController/blob/main/EMController/IPCController.swift) before running. The app UI employs a circular slider to control up to three frequencies simultaneously (in accordance with v1 of the prototype that supports up to three electromagnets).

![EMController_ESP32](https://github.com/ajdonich/pemf-prototype/blob/main/EMController_ESP32.png)
