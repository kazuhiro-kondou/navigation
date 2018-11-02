/*
 * Copyright (C) 2016 The Qt Company Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import QtQuick 2.6
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0
import QtWebSockets 1.0
import QtLocation 5.9
import QtPositioning 5.6
ApplicationWindow {
	id: root
	visible: true
	width: 1080
	height: 1488
	title: qsTr("TestQt")

    property real car_position_lat: 36.131516     // Las Vegas Convention Center
    property real car_position_lon: -115.151507
    property real car_direction: 0  //Noth
    property bool st_heading_up: false
    property real default_zoom_level : 18
    property real default_car_direction : 0

	Map{
		id: map
        property int pathcounter : 0
        property int segmentcounter : 0
        property int waypoint_count: -1
		property int lastX : -1
		property int lastY : -1
		property int pressX : -1
		property int pressY : -1
		property int jitterThreshold : 30
        property variant currentpostion : QtPositioning.coordinate(car_position_lat, car_position_lon)

        width: 1080
		height: 1488
		plugin: Plugin {
			name: "mapbox"
			PluginParameter { name: "mapbox.access_token";
			value: "pk.eyJ1IjoiYWlzaW53ZWkiLCJhIjoiY2pqNWg2cG81MGJoazNxcWhldGZzaDEwYyJ9.imkG45PQUKpgJdhO2OeADQ" }
		}
        center: QtPositioning.coordinate(car_position_lat, car_position_lon)
        zoomLevel: default_zoom_level
        bearing: 0

		GeocodeModel {
			id: geocodeModel
			plugin: map.plugin
			onStatusChanged: {
				if ((status == GeocodeModel.Ready) || (status == GeocodeModel.Error))
					map.geocodeFinished()
			}
			onLocationsChanged:
			{
				if (count == 1) {
					map.center.latitude = get(0).coordinate.latitude
					map.center.longitude = get(0).coordinate.longitude
				}
			}
            //coordinate: poiTheQtComapny.coordinate
            //anchorPoint: Qt.point(-poiTheQtComapny.sourceItem.width * 0.5,poiTheQtComapny.sourceItem.height * 1.5)
        }
		MapItemView {
			model: geocodeModel
			delegate: pointDelegate
		}
		Component {
			id: pointDelegate

			MapCircle {
				id: point
				radius: 1000
				color: "#46a2da"
				border.color: "#190a33"
				border.width: 2
				smooth: true
				opacity: 0.25
				center: locationData.coordinate
			}
		}

		function geocode(fromAddress)
		{
			// send the geocode request
			geocodeModel.query = fromAddress
			geocodeModel.update()
		}
		
        MapQuickItem {
            id: poi
            sourceItem: Rectangle { width: 14; height: 14; color: "#e41e25"; border.width: 2; border.color: "white"; smooth: true; radius: 7 }
            coordinate {
                latitude: 36.131516
                longitude: -115.151507
            }
            opacity: 1.0
            anchorPoint: Qt.point(sourceItem.width/2, sourceItem.height/2)
        }
        MapQuickItem {
            sourceItem: Text{
                text: "Convention Center"
                color:"#242424"
                font.bold: true
                styleColor: "#ECECEC"
                style: Text.Outline
            }
            coordinate: poi.coordinate
            anchorPoint: Qt.point(-poi.sourceItem.width * 0.5, poi.sourceItem.height * 1.5)
        }
        MapQuickItem {
            id: car_position_mapitem
            sourceItem: Image {
                id: car_position_mapitem_image
                width: 16
                height: 16
                source: "images/240px-Red_Arrow_Up.svg.png"

                transform: Rotation {
                    id: car_position_mapitem_image_rotate
                    origin.x: car_position_mapitem_image.width/2
                    origin.y: car_position_mapitem_image.height/2
                    angle: car_direction
                }
            }
            anchorPoint: Qt.point(car_position_mapitem_image.width/2, car_position_mapitem_image.height/2)
            coordinate: map.currentpostion


            states: [
                State {
                    name: "HeadingUp"
                    PropertyChanges { target: car_position_mapitem_image_rotate; angle: 0 }
                },
                State {
                    name: "NorthUp"
                    PropertyChanges { target: car_position_mapitem_image_rotate; angle: root.car_direction }
                }
            ]
            transitions: Transition {
                NumberAnimation { properties: "angle"; easing.type: Easing.InOutQuad }
            }
        }

        MapQuickItem {
            id: icon_start_point
            anchorPoint.x: icon_start_point_image.width/2
            anchorPoint.y: icon_start_point_image.height
            sourceItem: Image {
                id: icon_start_point_image
                width: 32
                height: 32
                source: "images/240px-HEB_project_flow_icon_04_checkered_flag.svg.png"
            }
        }

        MapQuickItem {
            id: icon_end_point
            anchorPoint.x: icon_end_point_image.width/2
            anchorPoint.y: icon_end_point_image.height
            sourceItem: Image {
                id: icon_end_point_image
                width: 32
                height: 32
                source: "images/Map_marker_icon_–_Nicolas_Mollet_–_Flag_–_Tourism_–_Classic.png"
            }
        }

        MapQuickItem {
            id: icon_segment_point
            sourceItem: Image {
                id: icon_segment_point_image
                width: 64
                height: 64
                x: -32
                y: -44
                source: "images/Map_symbol_location_02.png"
            }
        }

		RouteModel {
			id: routeModel
			plugin : map.plugin
			query:  RouteQuery {
				id: routeQuery
			}
			onStatusChanged: {
				if (status == RouteModel.Ready) {
					switch (count) {
					case 0:
						// technically not an error
					//	map.routeError()
						break
					case 1:
						map.pathcounter = 0
						map.segmentcounter = 0
//						console.log("1 route found")
//						console.log("path: ", get(0).path.length, "segment: ", get(0).segments.length)
//						for(var i = 0; i < get(0).path.length; i++){
//							console.log("", get(0).path[i])
//						}
                        console.log("1st instruction: ", get(0).segments[map.segmentcounter].maneuver.instructionText)
                        for( var i = 0; i < routeModel.get(0).segments.length; i++){
//                            console.log("segments[",i,"].maneuver.direction:" ,routeModel.get(0).segments[i].maneuver.direction)
//                            console.log("segments[",i,"].maneuver.instructionText:" ,routeModel.get(0).segments[i].maneuver.instructionText)
//                            console.log("segments[",i,"].maneuver.path[0]:" ,routeModel.get(0).segments[i].path[0].latitude,",",routeModel.get(0).segments[i].path[0].longitude)
//                            markerModel.addMarker(routeModel.get(0).segments[i].path[0]) // for debug
                        }
                        break
					}
				} else if (status == RouteModel.Error) {
				//	map.routeError()
				}
			}
		}
		
		Component {
			id: routeDelegate

			MapRoute {
				id: route
				route: routeData
				line.color: "#4658da"
				line.width: 10
				smooth: true
				opacity: 0.8
			}
		}
		
		MapItemView {
			model: routeModel
			delegate: routeDelegate
		}

        MapItemView{
            model: markerModel
            delegate: mapcomponent
        }

        Component {
            id: mapcomponent
            MapQuickItem {
                id: icon_destination_point
                anchorPoint.x: icon_destination_point_image.width/4
                anchorPoint.y: icon_destination_point_image.height
                coordinate: position

                sourceItem: Image {
                    id: icon_destination_point_image
                    width: 32
                    height: 32
                    source: "images/200px-Black_close_x.svg.png"
                }
            }
        }

        function addDestination(coord){
            if( waypoint_count < 0 ){
                initDestination()
            }

            if(waypoint_count == 0)  {
                // set icon_start_point
                icon_start_point.coordinate = currentpostion
                map.addMapItem(icon_start_point)
            }

            if(waypoint_count < 9){
                routeQuery.addWaypoint(coord)
                waypoint_count += 1

                btn_guidance.sts_guide = 1
                btn_guidance.state = "Routing"

                var waypointlist = routeQuery.waypoints
                for(var i=1; i<waypoint_count; i++) {
//                    markerModel.addMarker(waypointlist[i])

                    map.addPoiIcon(waypointlist[i].latitude,waypointlist[i].longitude,i % 5) // for Debug
                }

                routeModel.update()

                // update icon_end_point
                icon_end_point.coordinate = coord
                map.addMapItem(icon_end_point)
            }
        }

        function initDestination(){
            routeModel.reset();
            console.log("initWaypoint")

            // reset currentpostion
            map.currentpostion = QtPositioning.coordinate(car_position_lat, car_position_lon)

            routeQuery.clearWaypoints();
            routeQuery.addWaypoint(map.currentpostion)
            routeQuery.travelModes = RouteQuery.CarTravel
            routeQuery.routeOptimizations = RouteQuery.FastestRoute
            for (var i=0; i<9; i++) {
                routeQuery.setFeatureWeight(i, 0)
            }
            waypoint_count = 0
            pathcounter = 0
            segmentcounter = 0
            routeModel.update();
            markerModel.removeMarker();
       //     map.removeMapItem(markerModel);

            // remove MapItem
            map.removeMapItem(icon_start_point)
            map.removeMapItem(icon_end_point)
            map.removeMapItem(icon_segment_point)
            map.removeMapItem(poi_icon) // for Debug

            // update car_position_mapitem angle
            root.car_direction = root.default_car_direction

        }

		function calculateMarkerRoute()
		{
            var startCoordinate = QtPositioning.coordinate(car_position_lat, car_position_lon)

			console.log("calculateMarkerRoute")
			routeQuery.clearWaypoints();
            routeQuery.addWaypoint(startCoordinate)
            routeQuery.addWaypoint(mouseArea.lastCoordinate)
			routeQuery.travelModes = RouteQuery.CarTravel
			routeQuery.routeOptimizations = RouteQuery.FastestRoute
			for (var i=0; i<9; i++) {
				routeQuery.setFeatureWeight(i, 0)
			}
			routeModel.update();
		}

        // Calculate direction from latitude and longitude between two points
        function calculateDirection(lat1, lon1, lat2, lon2) {
            var curlat = lat1 * Math.PI / 180;
            var curlon = lon1 * Math.PI / 180;
            var taglat = lat2 * Math.PI / 180;
            var taglon = lon2 * Math.PI / 180;

            var Y  = Math.sin(taglon - curlon);
            var X  = Math.cos(curlat) * Math.tan(taglat) - Math.sin(curlat) * Math.cos(Y);
            var direction = 180 * Math.atan2(Y,X) / Math.PI;
            if (direction < 0) {
              direction = direction + 360;
            }
            return direction;
        }

        // Calculate distance from latitude and longitude between two points
        function calculateDistance(lat1, lon1, lat2, lon2)
        {
            var radLat1 = lat1 * Math.PI / 180;
            var radLon1 = lon1 * Math.PI / 180;
            var radLat2 = lat2 * Math.PI / 180;
            var radLon2 = lon2 * Math.PI / 180;

            var r = 6378137.0;

            var averageLat = (radLat1 - radLat2) / 2;
            var averageLon = (radLon1 - radLon2) / 2;
            var result = r * 2 * Math.asin(Math.sqrt(Math.pow(Math.sin(averageLat), 2) + Math.cos(radLat1) * Math.cos(radLat2) * Math.pow(Math.sin(averageLon), 2)));
            return Math.round(result);
        }

        // Setting the next car position from the direction and demonstration mileage
        function setNextCoordinate(curlat,curlon,direction,distance)
        {
            var radian = direction * Math.PI / 180
            var lat_per_meter = 111319.49079327358;
            var lat_distance = distance * Math.cos(radian);
            var addlat = lat_distance / lat_per_meter
            var lon_distance = distance * Math.sin(radian)
            var lon_per_meter = (Math.cos( (curlat+addlat) / 180 * Math.PI) * 2 * Math.PI * 6378137) / 360;
            var addlon = lon_distance / lon_per_meter
            map.currentpostion = QtPositioning.coordinate(curlat+addlat, curlon+addlon);
        }

        function addPoiIcon(lat,lon,type) {
            var poiItem;
            switch(type){
                case 0:
                    poiItem = Qt.createQmlObject("
                            import QtQuick 2.0;
                            import QtLocation 5.9;
                            MapQuickItem {
                                id: poi_icon;
                                anchorPoint.x: icon_flag_liteblue_image.width/2;
                                anchorPoint.y: icon_flag_liteblue_image.height;
                                sourceItem: Image {
                                    id: icon_flag_liteblue_image;
                                    width: 32;
                                    height: 37;
                                    source: \"images/Flag-export_lightblue.png\";
                                }
                            }
                        ",map,"dynamic");
                    break;
                case 1:
                    poiItem = Qt.createQmlObject("
                            import QtQuick 2.0;
                            import QtLocation 5.9;
                            MapQuickItem {
                                id: poi_icon;
                                anchorPoint.x: icon_building_image.width/2;
                                anchorPoint.y: icon_building_image.height;
                                sourceItem: Image {
                                    id: icon_building_image;
                                    width: 32;
                                    height: 37;
                                    source: \"images/BuildingIcon.png\";
                                }
                            }
                        ",map,"dynamic");
                    break;
                case 2:
                    poiItem = Qt.createQmlObject("
                            import QtQuick 2.0;
                            import QtLocation 5.9;
                            MapQuickItem {
                                id: poi_icon;
                                anchorPoint.x: icon_church_image.width/2;
                                anchorPoint.y: icon_church_image.height;
                                sourceItem: Image {
                                    id: icon_church_image;
                                    width: 32;
                                    height: 37;
                                    source: \"images/ChurchIcon.png\";
                                }
                            }
                        ",map,"dynamic");
                    break;
                case 3:
                    poiItem = Qt.createQmlObject("
                            import QtQuick 2.0;
                            import QtLocation 5.9;
                            MapQuickItem {
                                id: poi_icon;
                                anchorPoint.x: icon_restaurant_image.width/2;
                                anchorPoint.y: icon_restaurant_image.height;
                                sourceItem: Image {
                                    id: icon_restaurant_image;
                                    width: 32;
                                    height: 37;
                                    source: \"images/RestaurantMapIcon.png\";
                                }
                            }
                        ",map,"dynamic");
                    break;
                case 4:
                    poiItem = Qt.createQmlObject("
                            import QtQuick 2.0;
                            import QtLocation 5.9;
                            MapQuickItem {
                                id: poi_icon;
                                anchorPoint.x: icon_supermarket_image.width/2;
                                anchorPoint.y: icon_supermarket_image.height;
                                sourceItem: Image {
                                    id: icon_supermarket_image;
                                    width: 32;
                                    height: 37;
                                    source: \"images/SupermarketMapIcon.png\";
                                }
                            }
                        ",map,"dynamic");
                    break;
                default:
                    poiItem = null;
                    break;
            }

            if(poiItem === null) {
               console.log("error creating object" +  poiItem.errorString());
               return false;
            }

            poiItem.coordinate = QtPositioning.coordinate(lat, lon);
            map.addMapItem(poiItem);
            console.log("success creating object");
            return true;
        }

		MouseArea {
			id: mouseArea
			property variant lastCoordinate
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton
			
			onPressed : {
				map.lastX = mouse.x
				map.lastY = mouse.y
				map.pressX = mouse.x
				map.pressY = mouse.y
				lastCoordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y))
			}
			
			onPositionChanged: {
                if (mouse.button === Qt.LeftButton) {
					map.lastX = mouse.x
					map.lastY = mouse.y
				}
			}
			
			onPressAndHold:{
                if(btn_guidance.state !== "onGuide")
                {
                    if (Math.abs(map.pressX - mouse.x ) < map.jitterThreshold
                            && Math.abs(map.pressY - mouse.y ) < map.jitterThreshold) {
                        map.addDestination(lastCoordinate)
                    }
                }

			}
		}
        gesture.onFlickStarted: {
            btn_present_position.state = "Optional"
        }
        gesture.onPanStarted: {
            btn_present_position.state = "Optional"
        }
		function updatePositon()
		{
			console.log("updatePositon")
            if(pathcounter <= routeModel.get(0).path.length - 1){
//                console.log("path: ", pathcounter, "/", routeModel.get(0).path.length - 1, " segment: ", segmentcounter, "/", routeModel.get(0).segments.length - 1)
//                console.log("from_to:",map.currentpostion.latitude,",",map.currentpostion.longitude,",",routeModel.get(0).path[pathcounter].latitude,",",routeModel.get(0).path[pathcounter].longitude)
                // calculate distance
                var next_distance = calculateDistance(map.currentpostion.latitude,
                                                      map.currentpostion.longitude,
                                                      routeModel.get(0).path[pathcounter].latitude,
                                                      routeModel.get(0).path[pathcounter].longitude);
//                console.log("next_distance:",next_distance);

                // calculate direction
                var next_direction = calculateDirection(map.currentpostion.latitude,
                                                        map.currentpostion.longitude,
                                                        routeModel.get(0).path[pathcounter].latitude,
                                                        routeModel.get(0).path[pathcounter].longitude);
//                console.log("next_direction:",next_direction);

                // calculate next cross distance
                var next_cross_distance = calculateDistance(map.currentpostion.latitude,
                                                            map.currentpostion.longitude,
                                                            routeModel.get(0).segments[segmentcounter].path[0].latitude,
                                                            routeModel.get(0).segments[segmentcounter].path[0].longitude);
//                console.log("next_cross_distance:",next_cross_distance);
                // set next coordidnate
                if(next_distance < 25)
                {
                    map.currentpostion = routeModel.get(0).path[pathcounter]
                    if(pathcounter < routeModel.get(0).path.length - 1){
                        pathcounter++
                    }
                    else
                    {
                        btn_guidance.sts_guide = 0
                    }
                }else{
                    setNextCoordinate(map.currentpostion.latitude, map.currentpostion.longitude,next_direction,20)
                }
//                console.log("NextCoordinate:",map.currentpostion.latitude,",",map.currentpostion.longitude)

                // car_position_mapitem angle
                root.car_direction = next_direction

                if(btn_present_position.state === "Flowing")
                {
                    // update map.center
                    map.center = map.currentpostion
                }

                // report a new instruction if current position matches with the head position of the segment
                if(segmentcounter <= routeModel.get(0).segments.length - 1){
                     if(next_cross_distance < 25){
//                      console.log("new segment instruction: ", routeModel.get(0).segments[segmentcounter].maneuver.instructionText)
                        progress_next_cross.setProgress(0)
                        if(segmentcounter < routeModel.get(0).segments.length - 1){
                            segmentcounter++
                        }
                        if(segmentcounter === routeModel.get(0).segments.length - 1){
                            img_destination_direction.state = "12"
                            map.removeMapItem(icon_segment_point)
                        }else{
                            img_destination_direction.state = routeModel.get(0).segments[segmentcounter].maneuver.direction
                            icon_segment_point.coordinate = routeModel.get(0).segments[segmentcounter].path[0]
                            map.addMapItem(icon_segment_point)
                        }
                    }else{
                        // update progress_next_cross
                        progress_next_cross.setProgress(next_cross_distance)
                    }
                }
            }
		}
	}
		
    BtnPresentPosition {
        id: btn_present_position
        x: 942
    //		y: 1328
        y: 530      // for debug
    }

	BtnMapDirection {
        id: btn_map_direction
		x: 15
		y: 20
	}

    BtnGuidance {
        id: btn_guidance
		x: 940
		y: 20
	}

	BtnShrink {
        id: btn_shrink
		x: 23
//		y:1200
        y:400   // for debug
	}

	BtnEnlarge {
        id: btn_enlarge
		x: 23
//		y: 1330
        y:530   // for debug
	}

	ImgDestinationDirection {
        id: img_destination_direction
		x: 120
		y: 20
	}

    ProgressNextCross {
        id: progress_next_cross
		x: 225
		y: 20
	}
}
