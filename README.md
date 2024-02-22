Make sure to comment out the "&& cameraCanBeUsed" part in Permissions.swift if you want to run it as a standalone iPhone app because Unity also needs to have access to the Camera while this app does not:
    var nativePermissionsGranted: Bool {
        locationCanBeUsed && bluetoothCanBeUsed && cameraCanBeUsed
    }

Getting started

To run this sample project you need to edit MainViewController.swift with such content:

    owner_id = "\"owner_id_that_was_used_during_api_key_creation\""
    api_token = "\"your_generated_api_key\""


Api Key

In order to generate your API KEY you should go to platform.wiliot.com/account/security and press 'Add New'. In the Add Key dialog please choose Edge Management from dropdown menu 'Select Catalog' and press 'Generate'. Then you can use your API KEY to get Access Token.

Tokens
Access token and gateway token has limited life time. When it expires you should to refresh them.
