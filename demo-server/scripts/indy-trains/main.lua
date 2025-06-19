print("[trains] Starting Indy's Trains")
-- CODER'S NOTE: When using keyframes, your await() must be 1/2 second longer than your duration or the player/bot won't arrive before the next animation starts.


-- v1 remaining
   -- Fix Github documentation (?)
   -- Fix splitter to not ignore double string as delimiter (as opposed to single character)
   -- Make z-index off new variable "Platform Z" so we can make the z difference dynamic. 

-- v1.1 features
-- Cargo Train Enhancements
    -- Add pedestal
    -- Add cargo NPC
-- Animation Smoothing
    -- We may need to add extra key frames to arrival and departure to smooth arrival speed.
    -- Jitter is a bit annoying. 

-- v2 features
-- multi-car cargo trains (a matter of making scalable offset values and handling for cars to animate)
    -- make custom properties Cargo be a comma seperated value if cars is greater than 1
-- timed passenger trains (arrives and departs on a schedule, need to have multi-car implemented.)
    -- need a boarding interaction that causes player to board the train 

--properties for passenger trains
local passenger_train_required_properties = {"Start","End","Direction","Stop","Platform Z","Train Z"}
local passenger_train_optional_properties = {"Speed","Color"}
--properties for cargo trains
local cargo_train_required_properties = {"Start","End","Direction","Train Z"}
local cargo_train_optional_properties = {"Speed","Cars","Color","Driver Texture","Driver Animation"}
--properties for conductors
local conductor_required_properties = {"Train","1 Area"}
local conductor_optional_properties = {"1 Type","1 Name","Animation","Texture","Mug","Mug Animation","Direction"}

--defaults
local default_cars = 1
local default_driver_texture_path="/server/assets/indy-trains/conductor-prog.png"
local default_driver_animation_path="/server/assets/indy-trains/conductor-prog.animation"
local default_driver_mug_texture_path="/server/assets/indy-trains/conductor-prog-mug.png"
local default_driver_mug_animation_path="/server/assets/indy-trains/conductor-prog-mug.animation"
local default_color = "orange" --selects a different sprite sheet for engine and cars 
local default_speed = 1 --sets the speed it moves with 1 (one) being MMBN3-esque.

--setup variables
local train_cache = {} 
local conductor_cache = {}
local cargo_schedule = {}
local passenger_cache = {}
local track_cache = {}
local player_using_train_menu = {}

--purpose: splits a string based on a delimiter
--usaged: used at various points to seperate values
local function splitter(inputstr, sep)
    if sep == nil then
        sep = '%s'
    else
        sep = sep:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
    end
    
    local t = {}
    for str in (inputstr..sep):gmatch("(.-)"..sep) do
        table.insert(t, str)
    end
    return t
end
--Shorthand for async
function async(p)
    local co = coroutine.create(p)
    return Async.promisify(co)
end

--Shorthand for await
function await(v) return Async.await(v) end

--Find all trains in all areas, removes placeholders, and triggers them to start
--usage: runs on server boot to find all train and conductor objects and handle setup
function find_trains()
    local areas = Net.list_areas()
    --Check every area
    for i, area_id in next, areas do
        area_id = tostring(area_id)
        if not train_cache[area_id] then
            train_cache[area_id] = {}
        --Loop over all objects in area, spawning trains for each train object.
        local objects = Net.list_objects(area_id)
            for i, object_id in next, objects do    
                local object = Net.get_object_by_id(area_id, object_id)
                object_id = tostring(object_id)
                if object.type == "Passenger Train" then
                    --Grab the object data, cache it, and remove placeholder from the map
                    train_cache[area_id][object.name] = object
                    Net.remove_object(area_id, object_id)
                    print('[trains] Found the \''..object.name..'\' passenger train in '..area_id..'.tmx')
                    validate_passenger_train(area_id, object.name)

                elseif object.type == "Cargo Train" then
                    --Grab the object data, cache it, and remove placeholder from the map
                    train_cache[area_id][object.name] = object
                    Net.remove_object(area_id, object_id)
                    print('[trains] Checking the \''..object.name..'\' cargo train in '..area_id..'.tmx')
                    validate_cargo_train(area_id, object.name)
                end
            end
            local objects = Net.list_objects(area_id)
            for i, object_id in next, objects do    
                local object = Net.get_object_by_id(area_id, object_id)
                object_id = tostring(object_id)
                if object.type == "Conductor" then
                    --Grab the object data, cache it, and remove placeholder from the map
                    Net.remove_object(area_id, object_id)
                    print('[trains] Found \''..object.name..'\' conductor in '..area_id..'.tmx')
                    spawn_conductor(area_id, object)
                end
            end
        end
    end
end

--usage: called when a player selects an option from a train menu
--purpose: to spawn a train, pickup player, and depart (if track is not already occupied)
function summon_arriving_passenger_train(player_id)
    return async(function ()
        Net.fade_player_camera(player_id, {r=0, g=0, b=0, a=255}, 0)
        Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_arrive_short.ogg")
        --prepare variables
        local train_name = passenger_cache[player_id]['train']
        local area_id = Net.get_player_area(player_id)
        local train = train_cache[area_id][train_name]
        local trainProps = train.custom_properties
        local direction = trainProps["Direction"]
        --lock input, unlock camera, and fade in camera 
        Net.lock_player_input(player_id)
        Net.unlock_player_camera(player_id)
        Net.fade_player_camera(player_id, {r=0, g=0, b=0, a=0}, 2)

        local driver_id = train.name..'-driver-'..area_id
        local driver = Net.create_bot(driver_id,{name="", area_id=area_id, texture_path=trainProps["Driver Texture"], animation_path=trainProps["Driver Animation"], x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
        local car_id = train.name..'-car-'..area_id
        local driver = Net.create_bot(car_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..trainProps["Color"].."_car.png", animation_path="/server/assets/indy-trains/"..trainProps["Color"].."_car.animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
        local engine_id = train.name..'-engine-'..area_id
        local driver = Net.create_bot(engine_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..trainProps["Color"].."_train.png", animation_path="/server/assets/indy-trains/"..trainProps["Color"].."_train.animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
        
        local car_offset_x = 0
        local car_offset_y = 0
        local train_offset_x = 0
        local train_offset_y = 0
        local driver_offset_x = 0
        local driver_offset_y = 0
        local pedestal_offset_x = 0
        local pedestal_offset_y = 0
        local light_offset_x = 0
        local light_offset_y = 0

        if direction == "DL" then
            Net.animate_player(player_id, "IDLE_UL", true)  
            --less jitter
            car_offset_x = -.9534
            car_offset_y = -1.385
            train_offset_x = -.92
            train_offset_y = -.449
            driver_offset_x = -.45
            driver_offset_y = 0
            pedestal_offset_x = -.5
            pedestal_offset_y = .2
            light_offset_x = .28
            light_offset_y = -.6
        elseif direction == "DR" then
            Net.animate_player(player_id, "IDLE_UR", true)  
            --some jitter
            car_offset_x = -1.4
            car_offset_y = -.9
            train_offset_x = -.5
            train_offset_y = -.9
            driver_offset_x = 0
            driver_offset_y = -.4
            pedestal_offset_x = .209
            pedestal_offset_y = -.409
            light_offset_x = -.7
            light_offset_y = .3
        elseif direction == "UL" then
            Net.animate_player(player_id, "IDLE_UR", true)  
            --some jitter
            car_offset_x = -.15
            car_offset_y = -.95
            train_offset_x = -1.4
            train_offset_y = -1.25
            driver_offset_x = -.5
            driver_offset_y = -.4
            light_offset_x = .65
            light_offset_y = .3
        elseif direction == "UR" then --WORKING ON
            Net.animate_player(player_id, "IDLE_UL", true)  
            --some jitter
            car_offset_x = -.9
            car_offset_y = .1
            train_offset_x = -1.2
            train_offset_y = -1.2
            driver_offset_x = -.4
            driver_offset_y = -.4
            light_offset_x = .28
            light_offset_y = .8
        end 

        local pedestal_id = train.name..'-pedestal-'..area_id
        if direction == "DR" or direction == "DL" then
            --spawn pedestal
            local pedestal = Net.create_bot(pedestal_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/pedestal.png", animation_path="/server/assets/indy-trains/pedestal_"..trainProps["Color"]..".animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
        end

        start_to_stop = trainProps["Duration Start to Stop"]
        stop_to_end = trainProps["Duration Stop to End"]

        --Move player with Train to Station
        if direction == "DR" then
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=(trainProps["startX"]+1.5-.5+trainProps["offset"])},{property="Y",ease="Out",value=(trainProps["startY"]+1.35+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+1.5-.5+trainProps["offset"]},{property="Y",ease="Out",value=trainProps["stopY"]+1.35+trainProps["offset"]}},duration=start_to_stop}
            Net.animate_player_properties(player_id, keyframes) 

        elseif direction == "UL" then
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=(trainProps["startX"]+2.15+trainProps["offset"])},{property="Y",ease="Out",value=(trainProps["startY"]+1.4+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+2.15+trainProps["offset"]},{property="Y",ease="Out",value=trainProps["stopY"]+1.4+trainProps["offset"]}},duration=start_to_stop}
            Net.animate_player_properties(player_id, keyframes) 
        elseif direction == "UR" then
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=(trainProps["startX"]+1.4+trainProps["offset"])},{property="Y",ease="Out",value=(trainProps["startY"]+2.4+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+1.4+trainProps["offset"]},{property="Y",ease="Out",value=trainProps["stopY"]+2.4+trainProps["offset"]}},duration=start_to_stop}
            Net.animate_player_properties(player_id, keyframes) 

        elseif direction == "DL" then
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=(trainProps["startX"]+1.3+trainProps["offset"])},{property="Y",ease="Out",value=(trainProps["startY"]+1.05+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+1.3+trainProps["offset"]},{property="Y",ease="Out",value=trainProps["stopY"]+1.05+trainProps["offset"]}},duration=start_to_stop}
            Net.animate_player_properties(player_id, keyframes) 

        end 

        --Animation for Train Arriving at Station
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+driver_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+driver_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+driver_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+driver_offset_y}},duration=start_to_stop}
        Net.animate_bot_properties(driver_id, keyframes) 
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+car_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+car_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+car_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+car_offset_y}},duration=start_to_stop}
        Net.animate_bot_properties(car_id, keyframes) 
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+train_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+train_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+train_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+train_offset_y}},duration=start_to_stop}
        Net.animate_bot_properties(engine_id, keyframes) 

        if direction == "DR" or direction == "DL" then
            local keyframes = {{properties={{property="X",ease="Out",value=trainProps["startX"]+.5+pedestal_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+pedestal_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+pedestal_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+pedestal_offset_y}},duration=start_to_stop}
            Net.animate_bot_properties(pedestal_id, keyframes) 
        end

        await(Async.sleep(start_to_stop+1))

        --Animate Light Path 
        local lightpath_id = train.name..'-light-'..area_id
        local lightpath = Net.create_bot(lightpath_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/lightpath.png", animation_path="/server/assets/indy-trains/lightpath_"..trainProps["Color"]..".animation", x=trainProps["stopX"]+.5+light_offset_x, y=trainProps["stopY"]+.5+light_offset_y, z=trainProps["trainZ"], solid=false,warp_in=false })

        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",value=trainProps["stopX"]+.5+light_offset_x},{property="Y",value=trainProps["stopY"]+.5+light_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="X",ease="Linear",value=trainProps["stopX"]+.5+light_offset_x},{property="Y",ease="Linear",value=trainProps["stopY"]+.5+light_offset_y}},duration=0}
        Net.animate_bot_properties(lightpath_id, keyframes) 
        Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_jingle.ogg")

        await(Async.sleep(.5))

        --Animation for Player Disembarking train
        if direction == "DR" then
            local keyframes = {{properties={{property="Animation",value="WALK_DL"},{property="X",ease="Linear",value=(trainProps["stopX"]+1+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.35+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_DL"},{property="X",ease="Linear",value=trainProps["stopX"]+1.15+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.85+trainProps["offset"]}},duration=1}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_DL"},{property="X",ease="Linear",value=trainProps["stopX"]+1.15+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.85+trainProps["offset"]}},duration=0}
            Net.animate_player_properties(player_id, keyframes) 
        elseif direction == "UL" then
            local keyframes = {{properties={{property="Animation",value="WALK_DL"},{property="X",ease="Linear",value=(trainProps["stopX"]+2.15+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.4+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_DL"},{property="X",ease="Linear",value=trainProps["stopX"]+2.40+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.7+trainProps["offset"]}},duration=1}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_DL"},{property="X",ease="Linear",value=trainProps["stopX"]+2.40+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.7+trainProps["offset"]}},duration=0}
            Net.animate_player_properties(player_id, keyframes) 
        elseif direction == "UR" then
            local keyframes = {{properties={{property="Animation",value="WALK_DR"},{property="X",ease="Linear",value=(trainProps["stopX"]+1.4+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+2.4+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_DR"},{property="X",ease="Linear",value=trainProps["stopX"]+2.6+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.55+trainProps["offset"]}},duration=1}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_DR"},{property="X",ease="Linear",value=trainProps["stopX"]+2.6+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+2.55+trainProps["offset"]}},duration=0}
            Net.animate_player_properties(player_id, keyframes) 
        elseif direction == "DL" then
            local keyframes = {{properties={{property="Animation",value="WALK_DR"},{property="X",ease="Linear",value=(trainProps["stopX"]+1.3+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.05+trainProps["offset"])}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_DR"},{property="X",ease="Linear",value=trainProps["stopX"]+2.5+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+1.05+trainProps["offset"]}},duration=1}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_DR"},{property="X",ease="Linear",value=trainProps["stopX"]+2.5+trainProps["offset"]},{property="Y",ease="Linear",value=trainProps["stopY"]+1.05+trainProps["offset"]}},duration=0}
            Net.animate_player_properties(player_id, keyframes) 

        end 
        await(Async.sleep(1.5))

        Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_away.ogg")

        Net.unlock_player_input(player_id)
        Net.remove_bot(lightpath_id,false)

        --Animate driver leaving Station
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+driver_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+driver_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+driver_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+driver_offset_y}},duration=stop_to_end}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+train_offset_y}},duration=1}
        Net.animate_bot_properties(driver_id, keyframes) 
        --Animate car leaving Station
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+car_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+car_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+car_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+car_offset_y}},duration=stop_to_end}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+train_offset_y}},duration=1}
        Net.animate_bot_properties(car_id, keyframes) 
        --Animate engine leaving Station
        local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+train_offset_y}},duration=0}}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+train_offset_y}},duration=stop_to_end}
        keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+train_offset_y}},duration=1}
        Net.animate_bot_properties(engine_id, keyframes)
        --Animate pedestal leaving Station
        if direction == "DR" or direction == "DL" then
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+pedestal_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+pedestal_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+pedestal_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+pedestal_offset_y}},duration=stop_to_end}
            Net.animate_bot_properties(pedestal_id, keyframes)
        end
        await(Async.sleep(stop_to_end))
        --Remove bots
        if direction == "DR" or direction == "DL" then
            Net.remove_bot(pedestal_id,false)
        end
        Net.remove_bot(engine_id,false)
        Net.remove_bot(driver_id,false)
        Net.remove_bot(car_id,false)
        await(Async.sleep(.5))
        --Clear player specific cache
        passenger_cache[player_id]['intransit'] = false
        passenger_cache[player_id]['train'] = ""
        --Unoccupy track
        track_cache[area_id][train_name]['occupied'] = false
    end)    
end

function summon_departing_passenger_train(player_id,post_id)

    player_using_train_menu[player_id] = false
    Net.close_bbs(player_id)

    if post_id == "cancel" then
        return false
    end 

    local post_data = splitter(post_id,"__")
    local train_name = post_data[1]
    local destination_id = post_data[2]
    local area_id = Net.get_player_area(player_id)
    local destination_type = ""
    if not post_data[3] then 
        destination_type = "area"
    elseif string.lower(post_data[3]) == "area" then
        destination_type = "area"
    elseif string.lower(post_data[3]) == "server" then
        destination_type = "server"
    else 
        print("Invalid destination type of \""..post_data[3].."\".")
    end 
    if not track_cache[area_id] then
        track_cache[area_id] = {}
        track_cache[area_id][train_name] = {}
    end

    if track_cache[area_id][train_name]['occupied'] ~= true then

        Net.lock_player_input(player_id)
        if not passenger_cache[player_id] then
            passenger_cache[player_id] = {}
        end
        passenger_cache[player_id]['intransit'] = true
        passenger_cache[player_id]['train'] = train_name

        return async(function ()
            local train = train_cache[area_id][train_name]
            local trainProps = train.custom_properties
            track_cache[area_id][train_name]['occupied'] = true
            
            local direction = trainProps["Direction"]
            local car_offset_x = 0
            local car_offset_y = 0
            local train_offset_x = 0
            local train_offset_y = 0
            local driver_offset_x = 0
            local driver_offset_y = 0
            local pedestal_offset_x = 0
            local pedestal_offset_y = 0
            local light_offset_x = 0
            local light_offset_y = 0

            if direction == "DL" then
                Net.animate_player(player_id, "IDLE_UL", true)  
                --less jitter
                car_offset_x = -.9534
                car_offset_y = -1.385
                train_offset_x = -.92
                train_offset_y = -.449
                driver_offset_x = -.45
                driver_offset_y = 0
                pedestal_offset_x = -.5
                pedestal_offset_y = .2
                light_offset_x = .28
                light_offset_y = -.6
            elseif direction == "DR" then
                Net.animate_player(player_id, "IDLE_UR", true)  
                --some jitter
                car_offset_x = -1.4
                car_offset_y = -.9
                train_offset_x = -.5
                train_offset_y = -.9
                driver_offset_x = 0
                driver_offset_y = -.4
                pedestal_offset_x = .209
                pedestal_offset_y = -.409
                light_offset_x = -.7
                light_offset_y = .3
            elseif direction == "UL" then
                Net.animate_player(player_id, "IDLE_UR", true)  
                --some jitter
                car_offset_x = -.15
                car_offset_y = -.95
                train_offset_x = -1.4
                train_offset_y = -1.25
                driver_offset_x = -.5
                driver_offset_y = -.4
                light_offset_x = .65
                light_offset_y = .3
            elseif direction == "UR" then --WORKING ON
                Net.animate_player(player_id, "IDLE_UL", true)  
                --some jitter
                car_offset_x = -.9
                car_offset_y = .1
                train_offset_x = -1.2
                train_offset_y = -1.2
                driver_offset_x = -.4
                driver_offset_y = -.4
                light_offset_x = .28
                light_offset_y = .8
            end 
            --Spawning Train Bots
            local driver_id = train.name..'-driver-'..area_id
            local driver = Net.create_bot(driver_id,{name="", area_id=area_id, texture_path=trainProps["Driver Texture"], animation_path=trainProps["Driver Animation"], x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
            local car_id = train.name..'-car-'..area_id
            local driver = Net.create_bot(car_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..trainProps["Color"].."_car.png", animation_path="/server/assets/indy-trains/"..trainProps["Color"].."_car.animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
            local engine_id = train.name..'-engine-'..area_id
            local driver = Net.create_bot(engine_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..trainProps["Color"].."_train.png", animation_path="/server/assets/indy-trains/"..trainProps["Color"].."_train.animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
            local pedestal_id = train.name..'-pedestal-'..area_id
            
            if direction == "DR" or direction == "DL" then
                pedestal = Net.create_bot(pedestal_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/pedestal.png", animation_path="/server/assets/indy-trains/pedestal_"..trainProps["Color"]..".animation", x=trainProps["startX"], y=trainProps["startY"], z=trainProps["trainZ"], solid=false,warp_in=false })
            end

            local start_to_stop = trainProps["Duration Start to Stop"]
            local stop_to_end = trainProps["Duration Stop to End"]

            --Animation for Train Arriving at Station
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+driver_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+driver_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+driver_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+driver_offset_y}},duration=start_to_stop}
            Net.animate_bot_properties(driver_id, keyframes) 
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+car_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+car_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+car_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+car_offset_y}},duration=start_to_stop}
            Net.animate_bot_properties(car_id, keyframes) 
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["startX"]+.5+train_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+train_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+train_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+train_offset_y}},duration=start_to_stop}
            Net.animate_bot_properties(engine_id, keyframes) 


            if direction == "DR" or direction == "DL" then
                local keyframes = {{properties={{property="X",ease="Out",value=trainProps["startX"]+.5+pedestal_offset_x},{property="Y",ease="Out",value=trainProps["startY"]+.5+pedestal_offset_y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Out",value=trainProps["stopX"]+.5+pedestal_offset_x},{property="Y",ease="Out",value=trainProps["stopY"]+.5+pedestal_offset_y}},duration=start_to_stop}
                Net.animate_bot_properties(pedestal_id, keyframes) 
            end
            Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_arrive.ogg")
            await(Async.sleep(start_to_stop+1))

            --Light Path Animation
            local lightpath_id = train.name..'-light-'..area_id
            local lightpath = Net.create_bot(lightpath_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/lightpath.png", animation_path="/server/assets/indy-trains/lightpath_"..trainProps["Color"]..".animation", x=trainProps["stopX"]+.5+light_offset_x, y=trainProps["stopY"]+.5+light_offset_y, z=trainProps["trainZ"], solid=false,warp_in=false })

            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",value=trainProps["stopX"]+.5+light_offset_x},{property="Y",value=trainProps["stopY"]+.5+light_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="X",ease="Linear",value=trainProps["stopX"]+.5+light_offset_x},{property="Y",ease="Linear",value=trainProps["stopY"]+.5+light_offset_y}},duration=0}
            Net.animate_bot_properties(lightpath_id, keyframes) 
            Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_jingle.ogg")

            await(Async.sleep(1.5))
            Net.play_sound_for_player(player_id, "/server/assets/indy-trains/train_depart.ogg")

            --Animation for Player boarding train
            local player_position = Net.get_player_position(player_id)
            --Change player movements based on train direction 
            if direction == "DR" then --DONE
                --Animation for Player Boarding Train
                local keyframes = {{properties={{property="Animation",value="WALK_UR"},{property="X",ease="Linear",value=player_position.x},{property="Z",ease="Linear",value=player_position.z},{property="Y",ease="Linear",value=player_position.y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_UR"},{property="X",ease="Linear",value=(trainProps["stopX"]+1+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.35+trainProps["offset"])}},duration=1}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction}},duration=0}
                Net.animate_player_properties(player_id, keyframes) 
                await(Async.sleep(1.25))
                Net.remove_bot(lightpath_id,false)
                await(Async.sleep(.25))

                --Animation for Train and Player Departing Platform
                local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=(trainProps["stopX"]+1.5-.5+trainProps["offset"])},{property="Y",ease="In",value=(trainProps["stopY"]+1.35+trainProps["offset"])}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+1.5-.5+trainProps["offset"]},{property="Y",ease="In",value=trainProps["endY"]+1.35+trainProps["offset"]}},duration=stop_to_end}
                Net.animate_player_properties(player_id, keyframes) 

            elseif direction == "UL" then --DONE
                --Animation for Player Boarding Train
                local keyframes =         {{properties={{property="Animation",value="WALK_UR"},{property="X",ease="Linear",value=player_position.x},{property="Z",ease="Linear",value=player_position.z},{property="Y",ease="Linear",value=player_position.y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_UR"},{property="X",ease="Linear",value=(trainProps["stopX"]+2.15+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.4+trainProps["offset"])}},duration=1}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction}},duration=0}
                Net.animate_player_properties(player_id, keyframes) 
                await(Async.sleep(1.25))
                Net.remove_bot(lightpath_id,false)
                await(Async.sleep(.25))
                --Animation for Train and Player Departing Platform
                local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=(trainProps["stopX"]+2.15+trainProps["offset"])},{property="Y",ease="In",value=(trainProps["stopY"]+1.4+trainProps["offset"])}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+2.15+trainProps["offset"]},{property="Y",ease="In",value=trainProps["endY"]+1.4+trainProps["offset"]}},duration=stop_to_end}
                Net.animate_player_properties(player_id, keyframes) 

            elseif direction == "UR" then
                --Animation for Player Boarding Train
                local keyframes =         {{properties={{property="Animation",value="WALK_UL"},{property="X",ease="Linear",value=player_position.x},{property="Z",ease="Linear",value=player_position.z},{property="Y",ease="Linear",value=player_position.y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_UL"},{property="X",ease="Linear",value=(trainProps["stopX"]+1.4+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+2.4+trainProps["offset"])}},duration=1}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction}},duration=0}
                Net.animate_player_properties(player_id, keyframes) 
                await(Async.sleep(1.25))
                Net.remove_bot(lightpath_id,false)
                await(Async.sleep(.25))
                --Animation for Train and Player Departing Platform
                local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=(trainProps["stopX"]+1.4+trainProps["offset"])},{property="Y",ease="In",value=(trainProps["stopY"]+2.4+trainProps["offset"])}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+1.4+trainProps["offset"]},{property="Y",ease="In",value=trainProps["endY"]+2.4+trainProps["offset"]}},duration=stop_to_end}
                Net.animate_player_properties(player_id, keyframes) 
            elseif direction == "DL" then
                --Animation for Player Boarding Train
                local keyframes =         {{properties={{property="Animation",value="WALK_UL"},{property="X",ease="Linear",value=player_position.x},{property="Z",ease="Linear",value=player_position.z},{property="Y",ease="Linear",value=player_position.y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="WALK_UL"},{property="X",ease="Linear",value=(trainProps["stopX"]+1.3+trainProps["offset"])},{property="Y",ease="Linear",value=(trainProps["stopY"]+1.05+trainProps["offset"])}},duration=1}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction}},duration=0}
                Net.animate_player_properties(player_id, keyframes) 
                await(Async.sleep(1.25))
                Net.remove_bot(lightpath_id,false)
                await(Async.sleep(.25))
                --Animation for Train and Player Departing Platform
                local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=(trainProps["stopX"]+1.3+trainProps["offset"])},{property="Y",ease="In",value=(trainProps["stopY"]+1.05+trainProps["offset"])}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+1.3+trainProps["offset"]},{property="Y",ease="In",value=trainProps["endY"]+1.05+trainProps["offset"]}},duration=stop_to_end}
                Net.animate_player_properties(player_id, keyframes) 

            end 
            --Train Leaving Station Animation
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+driver_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+driver_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+driver_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+driver_offset_y}},duration=stop_to_end}
            Net.animate_bot_properties(driver_id, keyframes) 
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+car_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+car_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+car_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+car_offset_y}},duration=stop_to_end}
            Net.animate_bot_properties(car_id, keyframes) 
            local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+train_offset_y}},duration=0}}
            keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+train_offset_y}},duration=stop_to_end}
            Net.animate_bot_properties(engine_id, keyframes)
            if direction == "DR" or direction == "DL" then
                local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["stopX"]+.5+pedestal_offset_x},{property="Y",ease="In",value=trainProps["stopY"]+.5+pedestal_offset_y}},duration=0}}
                keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="In",value=trainProps["endX"]+.5+pedestal_offset_x},{property="Y",ease="In",value=trainProps["endY"]+.5+pedestal_offset_y}},duration=stop_to_end}
                Net.animate_bot_properties(pedestal_id, keyframes)
            end
            local fade_wait = stop_to_end/3
            await(Async.sleep(2*(fade_wait)))
            Net.fade_player_camera(player_id, {r=0, g=0, b=0, a=255}, fade_wait)
            local player_position = Net.get_player_position(player_id)
            Net.move_player_camera(player_id, player_position.x, player_position.y, player_position.z, fade_wait)
            await(Async.sleep(fade_wait+.5))
            Net.remove_bot(engine_id,false)
            Net.remove_bot(driver_id,false)
            Net.remove_bot(car_id,false)
            if direction == "DR" or direction == "DL" then
                Net.remove_bot(pedestal_id,false)
            end
            --Clear the track so a new train can be requested
            track_cache[area_id][train_name]['occupied'] = false

            --Handle an Area-to-Area transfer
            if destination_type == "area" then 
                local destination_train = train_cache[destination_id][train_name]
                local destination_trainProps = destination_train.custom_properties
                if not track_cache[destination_id] then
                    track_cache[destination_id] = {}
                end
                if not track_cache[destination_id][train_name] then
                    track_cache[destination_id][train_name] = {}
                end
                track_cache[destination_id][train_name]['occupied'] = true
            
                if direction == "DR" then
                    Net.transfer_player(player_id, destination_id, false, destination_trainProps["startX"]+1,destination_trainProps["startY"]+1.5,destination_trainProps["platformZ"], direction)    
                elseif direction == "UL" then
                    Net.transfer_player(player_id, destination_id, false, destination_trainProps["startX"]+2.15,destination_trainProps["startY"]+1.4,destination_trainProps["platformZ"], direction)    

                elseif direction == "UR" then
                    Net.transfer_player(player_id, destination_id, false, destination_trainProps["startX"]+1.4,destination_trainProps["startY"]+2.4,destination_trainProps["platformZ"], direction)    

                elseif direction == "DL" then
                    Net.transfer_player(player_id, destination_id, false, destination_trainProps["startX"]+1.3,destination_trainProps["startY"]+1.05,destination_trainProps["platformZ"], direction)    

                end 
            --Handle an Server-to-Server transfer
            else 
                local server_data = splitter(destination_id,",")
                local server_parts = splitter(server_data[1],":")
                local port = server_parts[2]
                local address = server_parts[1]
                local server_area = server_data[2]
                local server_train = server_data[3]
                Net.transfer_server(player_id, server_parts[1], server_parts[2], false, "trains__"..server_area.."__"..server_train) 
            end 
        end)
    else 
        local conductor = conductor_cache[area_id]['conductor-'..train.name..'-'..area_id]
        Net.message_player(player_id, "Another train is on the track, please wait for further traffic clearance.", conductor.custom_properties["Mug Texture"], conductor.custom_properties["Mug Animation"]) 
        
    end
end

--purpose: validates passenger train configuration, checks provided properties, and assigns necessary properties.
--usage: called on server boot for each passenger train object
function validate_passenger_train(area_id,train_name)
    local train = train_cache[area_id][train_name]
    for i, prop_name in pairs(passenger_train_required_properties) do
        if not train.custom_properties[prop_name] then
            print('   Train \''..train.name..'\' was not created because the custom property '..prop_name..' is required.')
            train.remove()
            return false
        else
        print('   '..prop_name..' = '..train.custom_properties[prop_name])
        end
    end  
    for i, prop_name in pairs(passenger_train_optional_properties) do
        if not train.custom_properties[prop_name] then
            print('   '..prop_name..' not set (default was used)')
        else
        print('   '..prop_name..' = '..train.custom_properties[prop_name])
        end
    end 

    -- set speed if not assigned
    if not train.custom_properties["Speed"] then
        train.custom_properties["Speed"] = 1 --may need to increase
    end
    if not train.custom_properties["Driver Texture"] then
        train.custom_properties["Driver Texture"] = default_driver_texture_path
    end
    if not train.custom_properties["Driver Animation"] then
        train.custom_properties["Driver Animation"] = default_driver_animation_path
    end
    --normalize direction
    direction = train.custom_properties["Direction"]
    if direction == "Down Left" then
        direction = "DL"
    elseif direction == "Up Left" then
        direction = "UL"
    elseif direction == "Up Right" then
        direction = "UR"
    elseif direction == "Down Right" then
        direction = "DR"
    else 
        print("[trains] "..direction.." is not a valid direction.")
        return false
    end
    train.custom_properties["Direction"] = direction
    -- normalize start position, end position, assign distance, assign duration
    startPoint = train.custom_properties["Start"]:gsub("%^ ", "")
    endPoint = train.custom_properties["End"]:gsub("%^ ", "")
    stopPoint = train.custom_properties["Stop"]:gsub("%^ ", "")
    local trainZ = tonumber(train.custom_properties["Train Z"])
    local platformZ = tonumber(train.custom_properties["Platform Z"])
    
    -- The "offset" value adjusts all player animations to accomodate the offset. 
    train.custom_properties["offset"] = ((platformZ - trainZ) - 3) * .5 + .1

    direction = train.custom_properties["Direction"]
    if not train.custom_properties["Color"] then
        train.custom_properties["Color"] = "orange"
    else
        train.custom_properties["Color"] = string.lower(train.custom_properties["Color"])
    end
    if train.custom_properties["Color"] == "orange" or train.custom_properties["Color"] == "blue" or train.custom_properties["Color"] == "gray" or train.custom_properties["Color"] == "red" or train.custom_properties["Color"] == "cyan" or train.custom_properties["Color"] == "green" then
    else
        print(train.custom_properties["Color"] .. " is not a valid color. Using orange.")
    end
    endPoints = splitter(endPoint,",")
    stopPoints = splitter(stopPoint,",")
    startPoints = splitter(startPoint,",")
    startX = tonumber(startPoints[1])
    startY = tonumber(startPoints[2])
    endX = tonumber(endPoints[1])
    endY = tonumber(endPoints[2])
    stopX = tonumber(stopPoints[1])
    stopY = tonumber(stopPoints[2])
    distance = 0
    start_to_stop = 0
    stop_to_end = 0
    if startY > endY then
        distance = startY - endY
        start_to_stop = startY - stopY
        stop_to_end = stopY - endY
    elseif startY < endY then
        distance = endY - startY
        start_to_stop = stopY - startY
        stop_to_end = endY - stopY
    elseif startX > endX then
        distance = startX - endX
        start_to_stop = startX - stopX
        stop_to_end = stopX - endX
    elseif startX < endX then
        distance = endX - startX
        start_to_stop = stopX - startX
        stop_to_end = endX - stopX
    end
    -- 30 blocks * (.25 / 1) = 7.5
    -- 30 * (.25 * 3) = 2.5
    duration = distance * (.25 / train.custom_properties["Speed"])
    start_to_stop = start_to_stop * (.25 / train.custom_properties["Speed"])
    stop_to_end = stop_to_end * (.25 / train.custom_properties["Speed"])
    train.custom_properties["Distance"] = distance
    train.custom_properties["Duration"] = duration
    train.custom_properties["Duration Start to Stop"] = start_to_stop
    train.custom_properties["Duration Stop to End"] = stop_to_end
    train.custom_properties["startX"] = startX
    train.custom_properties["startY"] = startY
    train.custom_properties["endX"] = endX
    train.custom_properties["endY"] = endY
    train.custom_properties["stopX"] = stopX
    train.custom_properties["stopY"] = stopY
    train.custom_properties["trainZ"] = trainZ
    train.custom_properties["platformZ"] = platformZ

    train_cache[area_id][train_name] = train
end

--purpose: populates and opens train route selection menu
--usage: called when player interacts with conductor
function greet_conductor(bot_id,player_id)
    local area_id = Net.get_player_area(player_id)
    local conductor = conductor_cache[area_id][bot_id]
    local conductorProps = conductor.custom_properties
    local train_name = splitter(bot_id,"-")[2]
    if not track_cache[area_id] then
        track_cache[area_id] = {}
        track_cache[area_id][train_name] = {}
    end
    if not track_cache[area_id][train_name] then
        track_cache[area_id][train_name] = {}
    end 

    if track_cache[area_id][train_name]['occupied'] == true then
        local conductor = conductor_cache[area_id]['conductor-'..train_name..'-'..area_id]
        Net.message_player(player_id, "Another train is on the track, please wait for further traffic clearance.", conductorProps["Mug Texture"], conductorProps["Mug Animation"]) 
        return false
    end

    player_using_train_menu[player_id] = true
    local board_color = { r= 120, g= 196, b= 159 }
    local posts = {}
    local post_type = ""
    local more_posts = false 
    local post_name = ""
    local post_id = ""
    local destination = conductorProps["1 Area"]
    if conductorProps["2 Area"] then
        more_posts = true
    end
    if conductorProps["1 Name"] then
        post_name = conductorProps["1 Name"]
    else 
        post_name = conductorProps["1 Area"]
    end

    if conductorProps["1 Type"] then
        if string.lower(conductorProps["1 Type"]) == "server" then
            post_type = "__server"
        end
    else
        post_type = "__area"
    end
    post_id = train_name.."__"..destination..post_type
    posts[#posts+1] = { id=post_id, read=true, title=post_name , author="" }
    while more_posts == true do
        if conductorProps[(#posts+1).." Type"] then
            if string.lower(conductorProps[(#posts+1).." Type"]) == "server" then
                post_type = "__server"
            end
        else
            post_type = "__area"
        end
        destination = conductorProps[(#posts+1).." Area"]
        post_id = train_name.."__"..destination..post_type
        if conductorProps[(#posts+1).." Name"] then
            post_name = conductorProps[(#posts+1).." Name"]
        else 
            post_name = conductorProps[(#posts+1).." Area"]
        end
        posts[#posts+1] = { id=post_id, read=true, title=post_name , author="" }
        if conductorProps[(#posts+1).." Area"] == nil then
            more_posts = false
        end
    end
    posts[#posts+1] = { id="cancel", read=true, title="Cancel" , author="" }
    Net.open_board(player_id, "Where to?", board_color, posts)

end

--purpose: validates conductor configuration, checks provided properties, assigns necessary properties, and spawns bot.
--usage: called on server boot for each conductor object
function spawn_conductor(area_id, object_data)
    conductor = object_data
    for i, prop_name in pairs(conductor_required_properties) do
        if not conductor.custom_properties[prop_name] then
            print('   Conductor for \''..conductor.custom_properties["Train"]..'\' was not created in '..area_id..' because the custom property '..prop_name..' is required.')
            conductor.remove()
            return false
        else
        print('   '..prop_name..' = '..conductor.custom_properties[prop_name])
        end
    end  
    for i, prop_name in pairs(conductor_optional_properties) do
        if not conductor.custom_properties[prop_name] then
            print('   '..prop_name..' not set (default was used)')
        else
        print('   '..prop_name..' = '..conductor.custom_properties[prop_name])
        end
    end 
    -- set default conductor NPC to driver 
    local conductor_name = "conductor-"..conductor.custom_properties["Train"]..'-'..area_id
    if not conductor_cache[area_id] then
        conductor_cache[area_id] = {}
    end 
    conductor_cache[area_id][conductor_name] = conductor
    if not conductor_cache[area_id][conductor_name].custom_properties["Texture"] then 
        conductor_cache[area_id][conductor_name].custom_properties["Texture"] = default_driver_texture_path
    end
    if not conductor_cache[area_id][conductor_name].custom_properties["Animation"] then
        conductor_cache[area_id][conductor_name].custom_properties["Animation"] = default_driver_animation_path
    end
    if not conductor_cache[area_id][conductor_name].custom_properties["Mug Texture"] then
        conductor_cache[area_id][conductor_name].custom_properties["Mug Texture"] = default_driver_mug_texture_path
    end
    if not conductor_cache[area_id][conductor_name].custom_properties["Mug Animation"] then
        conductor_cache[area_id][conductor_name].custom_properties["Mug Animation"] = default_driver_mug_animation_path
    end
    conductor = conductor_cache[area_id][conductor_name]
    train_direction = train_cache[area_id][conductor.custom_properties["Train"]].custom_properties["Direction"]
    if train_direction == "DR" or train_direction == "UL" then
        conductor_direction="DR"
    elseif train_direction == "DL" or train_direction == "UR" then
        conductor_direction="DL"
    end
    --spawn bot 
    Net.create_bot(conductor_name,{name="", area_id=area_id, texture_path=conductor.custom_properties["Texture"], animation_path=conductor.custom_properties["Animation"], x=conductor.x, animation="IDLE_"..conductor_direction, y=conductor.y, z=conductor.z, solid=true,warp_in=false })

end

--purpose: validates cargo train configuraton, checks properties, assigns necessary properties, and spawns bots.
--usage: called on server boot for each cargo train object
function validate_cargo_train(area_id,train_name)

    local train = train_cache[area_id][train_name]
    for i, prop_name in pairs(cargo_train_required_properties) do
        if not train.custom_properties[prop_name] then
            print('   Train \''..train.name..'\' was not created because the custom property '..prop_name..' is required.')
            train_cache[area_id][train_name].remove()
            return false
        else
        print('   '..prop_name..' = '..train.custom_properties[prop_name])
        end
    end  
    for i, prop_name in pairs(cargo_train_optional_properties) do
        if not train.custom_properties[prop_name] then
            print('   '..prop_name..' not set (default was used)')
        else
        print('   '..prop_name..' = '..train.custom_properties[prop_name])
        end
    end 

    -- set speed if not assigned
    if not train.custom_properties["Speed"] then
        train.custom_properties["Speed"] = 1
    end
    if not train.custom_properties["Driver Texture"] then
        train.custom_properties["Driver Texture"] = default_driver_texture_path
    end
    if not train.custom_properties["Driver Animation"] then
        train.custom_properties["Driver Animation"] = default_driver_animation_path
    end
    --normalize direction
    direction = train.custom_properties["Direction"]
    if direction == "Down Left" then
        direction = "DL"
    elseif direction == "Up Left" then
        direction = "UL"
    elseif direction == "Up Right" then
        direction = "UR"
    elseif direction == "Down Right" then
        direction = "DR"
    else 
        print("[trains] "..direction.." is not a valid direction.")
        return false
    end
    train.custom_properties["Direction"] = direction
    -- normalize start position, end position, assign distance, assign duration
    startPoint = train.custom_properties["Start"]:gsub("%^ ", "")
    endPoint = train.custom_properties["End"]:gsub("%^ ", "")
    direction = train.custom_properties["Direction"]
    if not train.custom_properties["Color"] then
        train.custom_properties["Color"] = "orange"
    else
        train.custom_properties["Color"] = string.lower(train.custom_properties["Color"])
    end
    if train.custom_properties["Color"] == "orange" or train.custom_properties["Color"] == "blue" or train.custom_properties["Color"] == "gray" or train.custom_properties["Color"] == "red" or train.custom_properties["Color"] == "cyan" or train.custom_properties["Color"] == "green" then
    else
        print(train.custom_properties["Color"] .. " is not a valid color. Using orange.")
    end
    endPoints = splitter(endPoint,",")
    startPoints = splitter(startPoint,",")
    startX = tonumber(startPoints[1])
    startY = tonumber(startPoints[2])
    trainZ = tonumber(train.custom_properties["Train Z"])
    endX = tonumber(endPoints[1])
    endY = tonumber(endPoints[2])

    distance = 0
    if startY > endY then
        distance = startY - endY
    elseif startY < endY then
        distance = endY - startY
    elseif startX > endX then
        distance = startX - endX
    elseif startX < endX then
        distance = endX - startX
    end
    duration = distance * (.25 / train.custom_properties["Speed"])
    train.custom_properties["Distance"] = distance
    train.custom_properties["Duration"] = duration
    train.custom_properties["startX"] = startX
    train.custom_properties["startY"] = startY
    train.custom_properties["endX"] = endX
    train.custom_properties["endY"] = endY
    train.custom_properties["trainZ"] = trainZ

    next_schedule = #cargo_schedule+1
    cargo_schedule[next_schedule] = {name=train_name,area=area_id,duration=duration,remaining=0}

    -- we will eventually need logic here to select proper driver, color, car length, and cargo
    local driver_id = train.name..'-driver-'..area_id
    local driver = Net.create_bot(driver_id,{name="", area_id=area_id, texture_path=train.custom_properties["Driver Texture"], animation_path=train.custom_properties["Driver Animation"], x=startX, y=startY, z=trainZ, solid=false,warp_in=false })
    local car_id = train.name..'-car-'..area_id
    local driver = Net.create_bot(car_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..train.custom_properties["Color"].."_car.png", animation_path="/server/assets/indy-trains/"..train.custom_properties["Color"].."_car.animation", x=startX, y=startY, z=trainZ, solid=false,warp_in=false })
    local engine_id = train.name..'-engine-'..area_id
    local driver = Net.create_bot(engine_id,{name="", area_id=area_id, texture_path="/server/assets/indy-trains/"..train.custom_properties["Color"].."_train.png", animation_path="/server/assets/indy-trains/"..train.custom_properties["Color"].."_train.animation", x=startX, y=startY, z=trainZ, solid=false,warp_in=false })

    if direction == "DR" or direction == "DL" then
    --Net.create_bot() --pedestal NPC (if down_left or down_right for Direction)
    end
    --Net.create_bot() --cargo(s) NPC

end

--animate a given cargo train for one loop
--usage: called within the Net.on("tick") function whenever a given cargo train's animation ends 
function run_cargo_train(area_id,train_name)
    train = train_cache[area_id][train_name]
    trainProps = train.custom_properties
    --print('[trains] \''..train.name..'\' cargo train departed.')
    --we need to animate the engine NPC, driver NPC, car NPC, and cargo NPC which will all be positioned relative to each other and moved together. 
    local direction = trainProps["Direction"] --DL UL DR UR
    -- we need custom offsets for each direction as the car should spawn behind and that changes based on direction. 
    if direction == "DL" then
        --less jitter
        car_offset_x = -.9534
        car_offset_y = -1.385
        train_offset_x = -.92
        train_offset_y = -.449
        driver_offset_x = -.45
        driver_offset_y = 0
    elseif direction == "DR" then
        --some jitter
        car_offset_x = -1.4
        car_offset_y = -.9
        train_offset_x = -.5
        train_offset_y = -.9
        driver_offset_x = 0
        driver_offset_y = -.4
    elseif direction == "UL" then
        --some jitter
        car_offset_x = -.15
        car_offset_y = -.95
        train_offset_x = -1.4
        train_offset_y = -1.25
        driver_offset_x = -.5
        driver_offset_y = -.4
    elseif direction == "UR" then
        --some jitter
        car_offset_x = -.9
        car_offset_y = .1
        train_offset_x = -1.2
        train_offset_y = -1.2
        driver_offset_x = -.4
        driver_offset_y = -.4
    end 
    local duration = trainProps["Duration"]
    local driver_id = train.name..'-driver-'..area_id
    local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["startX"]+.5+driver_offset_x},{property="Y",ease="Linear",value=trainProps["startY"]+.5+driver_offset_y}},duration=0}}
    keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["endX"]+.5+driver_offset_x},{property="Y",ease="Linear",value=trainProps["endY"]+.5+driver_offset_y}},duration=duration}
    Net.animate_bot_properties(driver_id, keyframes) 
    local car_id = train.name..'-car-'..area_id
    local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["startX"]+.5+car_offset_x},{property="Y",ease="Linear",value=trainProps["startY"]+.5+car_offset_y}},duration=0}}
    keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["endX"]+.5+car_offset_x},{property="Y",ease="Linear",value=trainProps["endY"]+.5+car_offset_y}},duration=duration}
    Net.animate_bot_properties(car_id, keyframes) 
    local engine_id = train.name..'-engine-'..area_id
    local keyframes = {{properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["startX"]+.5+train_offset_x},{property="Y",ease="Linear",value=trainProps["startY"]+.5+train_offset_y}},duration=0}}
    keyframes[#keyframes+1] = {properties={{property="Animation",value="IDLE_"..direction},{property="X",ease="Linear",value=trainProps["endX"]+.5+train_offset_x},{property="Y",ease="Linear",value=trainProps["endY"]+.5+train_offset_y}},duration=duration}
    Net.animate_bot_properties(engine_id, keyframes) 

    if direction == "DR" or direction == "DL" then
    --animate pedestal
    end

end

find_trains()

Net:on("actor_interaction", function(event)
  if string.find(event.actor_id, "conductor-") then
    greet_conductor(event.actor_id,event.player_id)
  end
end)

Net:on("player_disconnect", function(event)
    -- if a player disconnects we need to clear certain trackers
    if player_using_train_menu[event.player_id] then 
        player_using_train_menu[event.player_id] = false
    end 
    if passenger_cache[event.player_id] then
        passenger_cache[event.player_id]['intransit'] = false
    end 
end)


Net:on("post_selection", function(event)
  -- checks if player is in a train menu
    if player_using_train_menu[event.player_id] == true then
        --summons train based on train_name and chosen destination
        summon_departing_passenger_train(event.player_id,event.post_id)
    end
end)

Net:on("player_area_transfer", function(event)
    -- checks if a player is currently ridding a train
    if passenger_cache[event.player_id]['intransit'] == true then
        --calls function to grab transferred player, place them on the train, and drop off at platform 
        summon_arriving_passenger_train(event.player_id)
    end
end)

Net:on("player_request", function(event)
    -- on arrival we add the player to the passenger_cache and transfer them causing spawn_arrival_passenger_train to be called 
    if event.data ~= "" then
        -- checks for data format used by train mod
        if string.find(event.data, "trains__") then
            print(event.data)
            local post_data = splitter(event.data,"__")
            if not passenger_cache[event.player_id] then
                passenger_cache[event.player_id] = {}
            end
                local destination_area = post_data[2]
                local train_name = post_data[3]
                passenger_cache[event.player_id]['train'] = train_name
                passenger_cache[event.player_id]['intransit'] = true
                --checks if requested train exists in requested area exists
                if train_cache[destination_area][train_name] then
                    local destination_trainProps = train_cache[destination_area][train_name].custom_properties
                    Net.transfer_player(event.player_id, destination_area, false, destination_trainProps["startX"]+1,destination_trainProps["startY"]+1.5,destination_trainProps["platformZ"], direction)    
                    if not track_cache[destination_area] then 
                        track_cache[destination_area] = {}
                    end
                    if not track_cache[destination_area][train_name] then 
                        track_cache[destination_area][train_name] = {}
                    end 
                    track_cache[destination_area][train_name]['occupied'] = true
                    summon_arriving_passenger_train(event.player_id)
                end
                -- if not we just dump them off at the Home Warp 
        end 
    end
end)

Net:on("tick", function(event)
    --checks the Cargo Train schedule and handles animation loop 
    for i, train in next,cargo_schedule do
        if train["remaining"] <= 0 then
            run_cargo_train(train["area"],train["name"])
            train["remaining"] = train["duration"]
        else
            train["remaining"] = train["remaining"] - event.delta_time
        end
    end 

end)
