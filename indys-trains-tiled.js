
/* --------------------------------------- *\
   Indy's Trains - Tiled Extension for ONB
    github.com/indianajson/cyber-trains/
/* --------------------------------------- */

function addConductor() {
    // Ensure a map is open
    var map = tiled.activeAsset;
    if ((!map || !map.isTileMap)) {
        tiled.alert("Please open a Tiled map to use this action.");
        return;
    }
    // Ensure an Object layer is selected
    if (!(map.currentLayer.isObjectLayer)) {
        tiled.alert("Please select an object layer to add the cargo train.");
        return;
    }

    // Build the dialog
    var dialog = new Dialog("Configure Conductor");
    var cancelButton = dialog.addButton("Cancel");
    cancelButton.clicked.connect(dialog.reject);
    var okButton = dialog.addButton("Add Conductor");
    var nameField = dialog.addTextInput("Conductor Name", "");
    dialog.addNewRow();
    var trainField = dialog.addTextInput("Associated Train Name", "");
    var area_count = 1;
    dialog.addNewRow();
    var textureField = dialog.addTextInput("Texture (optional)", "");
    var animationField = dialog.addTextInput("Animation (optional)", "");
    dialog.addNewRow();
    var mugTextureField = dialog.addTextInput("Mug Texture (optional)", "");
    var mugAnimationField = dialog.addTextInput("Mug Animation (optional)", "");
    dialog.addNewRow();
    var destinations = [];
    var destination_label = [];
    var destination_type = [];
    destinations[area_count] = dialog.addTextInput("Destination #"+area_count.toString()+" (Area or IP)", "");
    dialog.addNewRow();
    destination_label[area_count] = dialog.addTextInput("Destination #"+area_count.toString()+" Label", "");
    dialog.addNewRow();
    destination_type[area_count] = dialog.addComboBox("Destination #"+area_count.toString()+" Type", ["Area-to-Area","Server-to-Server"]);
    dialog.addNewRow();
    var newButton = dialog.addButton("Add Another Destination");
    //When clicked new elements are added
    newButton.clicked.connect(function(){
        area_count = area_count + 1; 
        destinations[area_count] = dialog.addTextInput("Destination #"+area_count.toString()+" (Area or IP)", "");
        dialog.addNewRow();
        destination_label[area_count] = dialog.addTextInput("Destination #"+area_count.toString()+" Label", "");
        dialog.addNewRow();
        destination_type[area_count] = dialog.addComboBox("Destination #"+area_count.toString()+" Type", ["Area-to-Area","Server-to-Server"]);
        dialog.addNewRow();
    });
    dialog.addLabel("Don't need the extra destinations you added? Leave them blank.");
    dialog.addNewRow();

    // Main Buttons
    okButton.clicked.connect(function(){
        //A variety of validation checks to ensure the train is likely configured properly 
        if (!nameField.text) {
            tiled.alert("Conductor Name must be set.");
            return;
        }
        if (!trainField.text) {
            tiled.alert("Associated Train must be set.");
            return;
        }
        if (!destinations[1].text ) {
            tiled.alert("Destination #1 Area/IP must be set.");
            return;
        }
        if (!destination_label[1].text ) {
            tiled.alert("Destination #1 Label must be set.");
            return;
        }
        var view = tiled.mapEditor.currentMapView;
        var center = view.center;
        var obj = new MapObject();
        obj.shape = MapObject.Point;
        obj.x = center.x;
        obj.y = center.y;
        obj.name = nameField.text;
        obj.type = "Conductor"; 
        
        var error = 0;
        //Loop checking all added destinations for valuation then setting property value
        destinations.forEach(function(destination,i) {
            obj.setProperty("1 Area", destinations[i].text);
            if (i != 1 && destinations[i].text == ""){
                return true;
            }
            if (destination_type[i].currentText == "Area-to-Area"){
                if (checkArea(destinations[i].text) == false){
                    tiled.alert("Destination #"+i.toString()+" is malformed (no periods or .tmx).");
                    error = 1;
                }else{
                    obj.setProperty(i.toString()+" Area", destinations[i].text);
                    obj.setProperty(i.toString()+" Type", "Area");
                    obj.setProperty(i.toString()+" Label", destination_label[i].text);
                }
            }else if (destination_type[i].currentText == "Server-to-Server"){
                if (checkServer(destinations[i].text) == false){
                    tiled.alert("Destination #"+i.toString()+" is malformed (IP:port,area,trainid).");
                    error = 1;
                }else{
                    obj.setProperty(i.toString()+" Area", destinations[i].text);
                    obj.setProperty(i.toString()+" Type", "Server");
                    obj.setProperty(i.toString()+" Label", destination_label[i].text);
                }
            }
            
        });
        if (error == 1){
            return false;
        }
        obj.setProperty("Train", trainField.text);
        if (textureField.text)
            obj.setProperty("Texture", textureField.text);
        if (animationField.text)
            obj.setProperty("Animation", animationField.text);
        if (mugTextureField.text)
            obj.setProperty("Texture", mugTextureField.text);
        if (mugAnimationField.text)
            obj.setProperty("Animation", mugAnimationField.text);
        map.currentLayer.addObject(obj);
        dialog.close();
    });
    
   dialog.show();

}

function addCargoTrain() {
    // Ensure a map is open
    var map = tiled.activeAsset;
    if ((!map || !map.isTileMap)) {
        tiled.alert("Please open a Tiled map to use this action.");
        return;
    }
    // Ensure an Object layer is selected
    if (!(map.currentLayer.isObjectLayer)) {
        tiled.alert("Please select an object layer to add the cargo train.");
        return;
    }

    // Build the dialog
    var dialog = new Dialog("Configure Cargo Train");
    // Train ID
    var idField = dialog.addTextInput("Train Name", "");
    // Color dropdown
    var colorBox = dialog.addComboBox("Color", ["Orange", "Red", "Green", "Blue", "Cyan", "Gray"]);
    // Speed
    var speedField = dialog.addTextInput("Speed", "1");
    // Direction dropdown
    var directionBox = dialog.addComboBox("Direction", ["Down Right", "Down Left", "Up Right", "Up Left"]);
    // Start, End Points
    var startField = dialog.addTextInput("Start Point (X,Y,Z)", "");
    dialog.addNewRow()
    var endField = dialog.addTextInput("End Point (X,Y,Z)", "");
    dialog.addNewRow()
    // Driver texture & animation
    var driverTextureField = dialog.addTextInput("Driver Texture (optional)", "");
    dialog.addNewRow()
    var driverAnimationField = dialog.addTextInput("Driver Animation (optional)", "");
    dialog.addNewRow()
    // Driver texture & animation
    var cargoTextureField = dialog.addTextInput("Cargo Texture (optional)", "");
    dialog.addNewRow()
    var cargoAnimationField = dialog.addTextInput("Cargo Animation (optional)", "");
    dialog.addNewRow()
    // Buttons
    var cancelButton = dialog.addButton("Cancel");
    cancelButton.clicked.connect(dialog.reject);
    var okButton = dialog.addButton("Add Train");
    okButton.clicked.connect(function(){
        //A variety of validation checks to ensure the train is likely configured properly 
        
        if (!speedField.text) {
            tiled.alert("Speed must have a value.");
            return;
        }
        if (!idField.text ) {
            tiled.alert("Train Name must have a value.");
            return;
        }
        if (!startField.text) {
            tiled.alert("Start Point must have a value.");
            return;
        }
        if (!endField.text) {
            tiled.alert("End Point must have a value.");
            return;
        }
        
        //Check if start, end, and stop are formatted correctly
        
        if (checkXYZ(startField.text) == false){
            tiled.alert("Start Point is malformed. Include three numbers seperated by commas (\"1.2,0,0\").")
            return;
        }
        
        if (checkXYZ(endField.text) == false){
            tiled.alert("End Point is malformed. Include three numbers seperated by commas (\"1.2,0,0\").")
            return;
        }
        
        if (checkSpeed(speedField.text) == false){
            tiled.alert("Speed is malformed. Only use a number (\"0.1\" or \"2\"). ")
            return;
        }
        
        var view = tiled.mapEditor.currentMapView;
        var center = view.center;
        var obj = new MapObject();
        obj.shape = MapObject.Point;
        obj.x = center.x;
        obj.y = center.y;
        obj.name = idField.text;
        obj.type = "Cargo Train"; 
        // Set custom properties
        obj.setProperty("Color", colorBox.currentText);
        obj.setProperty("Speed", speedField.text);
        obj.setProperty("Direction", directionBox.currentText);
        obj.setProperty("Start", startField.text);
        obj.setProperty("End", endField.text);
        if (driverTextureField.text){
            obj.setProperty("Driver Texture", driverTextureField.text);
            }
        if (driverAnimationField.text){
            obj.setProperty("Driver Animation", driverAnimationField.text);
            }
        if (cargoTextureField.text){
            obj.setProperty("Cargo Texture", cargoTextureField.text);
            }
        if (cargoAnimationField.text){
            obj.setProperty("Cargo Animation", cargoAnimationField.text);
            }
        // Add to the object layer
        
        map.currentLayer.addObject(obj);
        dialog.close();
        
    });
    
   dialog.show();

}

function addPassengerTrain() {
    // Ensure a map is open
    var map = tiled.activeAsset;
    if ((!map || !map.isTileMap)) {
        tiled.alert("Please open a Tiled map to use this action.");
        return;
    }
    // Ensure an Object layer is selected
    if (!(map.currentLayer.isObjectLayer)) {
        tiled.alert("Please select an object layer to add the passenger train.");
        return;
    }

    // Build the dialog
    var dialog = new Dialog("Configure Passenger Train");
    // Train ID
    var idField = dialog.addTextInput("Train Name", "");
    // Color dropdown
    var colorBox = dialog.addComboBox("Color", ["Orange", "Red", "Green", "Blue", "Cyan", "Gray"]);
    // Speed
    var speedField = dialog.addTextInput("Speed", "1");
    // Direction dropdown
    var directionBox = dialog.addComboBox("Direction", ["Down Right", "Down Left", "Up Right", "Up Left"]);
    // Start, Stop, End points
    var startField = dialog.addTextInput("Start Point (X,Y,Z)", "");
    dialog.addNewRow()
    var stopField = dialog.addTextInput("Station Stop (X,Y,Z)", "");
    dialog.addNewRow()
    var endField = dialog.addTextInput("End Point (X,Y,Z)", "");
    dialog.addNewRow()
    // Driver texture & animation
    var driverTextureField = dialog.addTextInput("Driver Texture (optional)", "");
    dialog.addNewRow()
    var driverAnimationField = dialog.addTextInput("Driver Animation (optional)", "");
    dialog.addNewRow()
    // Buttons
    var cancelButton = dialog.addButton("Cancel");
    cancelButton.clicked.connect(dialog.reject);
    var okButton = dialog.addButton("Add Train");
    okButton.clicked.connect(function(){
        //A variety of validation checks to ensure the train is likely configured properly 
        if (!speedField.text) {
            tiled.alert("Speed must have a value.");
            return;
        }
        if (!idField.text ) {
            tiled.alert("Train Name must have a value.");
            return;
        }
        if (!startField.text) {
            tiled.alert("Start Point must have a value.");
            return;
        }
        if (!stopField.text) {
            tiled.alert("Station Stop Point must have a value.");
            return;
        }
        if (!endField.text) {
            tiled.alert("End Point must have a value.");
            return;
        }
        //Check if start, end, and stop are formatted correctly
        if (checkXYZ(startField.text) == false){
            tiled.alert("Start Point is malformed. Include three numbers seperated by commas (\"1.2,0,0\").")
            return;
        }
        if (checkXYZ(stopField.text) == false){
            tiled.alert("Stop Point is malformed. Include three numbers seperated by commas (\"1.2,0,0\").")
            return;
        }
        if (checkXYZ(endField.text) == false){
            tiled.alert("End Point is malformed. Include three numbers seperated by commas (\"1.2,0,0\").")
            return;
        }
        if (checkSpeed(speedField.text) == false){
            tiled.alert("Speed is malformed. Only use a number (\"0.1\" or \"2\"). ")
            return;
        }
        tiled.log("speed = "+idField.text)
        var view = tiled.mapEditor.currentMapView;
        var center = view.center;
        var obj = new MapObject();
        obj.shape = MapObject.Point;
        obj.x = center.x;
        obj.y = center.y;
        obj.name = idField.text;
        obj.type = "Passenger Train"; 
        // Set custom properties
        obj.setProperty("Color", colorBox.currentText);
        obj.setProperty("Speed", speedField.text);
        obj.setProperty("Direction", directionBox.currentText);
        obj.setProperty("Start", startField.text);
        obj.setProperty("Stop", stopField.text);
        obj.setProperty("End", endField.text);
        if (driverTextureField.text)
            obj.setProperty("Driver Texture", driverTextureField.text);
        if (driverAnimationField.text)
            obj.setProperty("Driver Animation", driverAnimationField.text);
        // Add to the object layer
        map.currentLayer.addObject(obj);
        dialog.close();
    });
    
   dialog.show();

}

function checkXYZ(textValue) {
    if (typeof textValue !== 'string') return false;

    const commaCount = textValue.split(',').length - 1;
    const dotCount = textValue.split('.').length - 1;

    // Check for invalid chars (digits, commas, dots only)
    for (const char of textValue) {
        if (!(char >= '0' && char <= '9') && char !== ',' && char !== '.') {
            return false;
        }
    }

    return commaCount === 2 && dotCount <= 3;
}
function checkSpeed(textValue) {
  return /^[0-9]*\.?[0-9]*$/.test(textValue) && 
    (textValue.match(/\./g) || []).length <= 1;
}
function checkArea(textValue) {
  return !textValue.includes(".tmx") && !textValue.includes(".");
}

function checkServer(textValue) {
  // Split by comma and trim whitespace from each part
  const parts = textValue.split(',').map(part => part.trim());
  
  // Must have exactly 3 parts
  if (parts.length !== 3) return false;
  
  const firstPart = parts[0];
  
  if (!firstPart.includes(':')) return false;
  
  const subParts = firstPart.split(':');
  const beforeColon = subParts[0];
  const afterColon = subParts[1];
  
  // Check there's exactly one colon (split returns array of length 2)
  if (subParts.length !== 2) return false;
  
  // Check there's at least one period before colon, not adjacent to colon
  if (!beforeColon.includes('.') || 
      beforeColon.endsWith('.')) return false;
  
  // Check only numbers after colon (and not empty)
  if (!/^\d+$/.test(afterColon)) return false;
  
  // If we got here, first part is valid and we have exactly 3 parts
  return true;
}

// Register the action and add it to the "New" menu
var action = tiled.registerAction("AddPassengerTrain", addPassengerTrain);
action.text = "Add Passenger Train...";
tiled.extendMenu("New", [{ action: "AddPassengerTrain" }]);
var action = tiled.registerAction("AddConductor", addConductor);
action.text = "Add Train Conductor...";
tiled.extendMenu("New", [{ action: "AddConductor" }]);
var action = tiled.registerAction("AddCargoTrain", addCargoTrain);
action.text = "Add Cargo Train...";
tiled.extendMenu("New", [{ action: "AddCargoTrain" }]);
