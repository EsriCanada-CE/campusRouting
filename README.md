#iOS Campus Routing App

Esri Canada has developed a configurable iOS app for your campus routing needs. The app supports routing point to point on your campus map and supports interior and exterior 3D networks. Restrictions such as routing indoors can be enabled in the app if supported by the network graph. Routing to library stacks based on Library of Congress call numbers is also possible.

##Requirements

###Hardware and Software
 
The shortest path routing is performed server side on ArcGIS Server. To deploy the app with your data the following hardware and software are required:
*	A Mac with XCode 6 or greater
*	ArcGIS Server with Network Analyst 10.2 or greater
*	ArcGIS Desktop 10.2 or greater

The app supports both iPhone and iPad with iOS 6 or greater.

###Data

The supporting app data must use the schema provided in the map package included in the repository. Listed below are the app data requirements:
*	A network graph spanning the area of interest
*	A set of point features used for starting and ending route locations
*	(Optional) A mosaic dataset of raster floorplans or a polyline/polygon feature class of the floorplans
*	(Optional) A polyline feature class of stack ranges for routing to books in libraries
*	(Optional) A point feature class to display as a layer on the map (e.g. bus stops, emergency beacons)

##Preparing your data

1.	Open the map package in ArcMap
2.	Project your data to WGS 1984 Web Mercator
3.	Expand the “routing” geodatabase in the Catalog pan and right click on the feature you would like to load data into
4.	Click Load-> Load data in the context menu
5.	Follow the wizard to choose the data to load, ensuring the attributes are set correctly
6.	Repeat Steps 3 to 5 for all data layers
7.	Right click on the network_ND network dataset and click “Build” in the context menu
8.	Zoom to the extent of the campus
 
##Publishing ArcGIS Services

9.	Open the map package.
10.	In ArcMap click File -> Share As -> Service...
11.	Click through the wizard, choosing to “Publish a Service” and click “Next”
12.	Choose an ArcGIS Server instance you are connected to and give the service a name and click “Next”
13.	Pick a location for the service and click “Next” 
14.	Once you get to the Service Editor window, go to the Capabilities page and check that Network Analysis is enabled     
15.	Click Publish and click OK when the dialog comes up about copying the data to the server
16.	Once the app is published, go to the server Manager (this can be found in the Start Menu of the server under ArcGIS -> Arcgis for Server)
17.	Create a user with an administrator role
18.	Change the security settings for the service to Private, and grant access to the administrator role you created



A settings.plist file is used toggle features such as indoor routing and to change the data configuration, such as the network analyst URL. Only certain values are used depending on what functionality is exposed in the app.

Key|Example Value|Description
---|---|---
username |Jdoe|ArcGIS Server username
password|testing|ArcGIS Server password
clientId|“fsDdajsef7Djdr79d”|ArcGIS Online Application Client ID
restriction|Restriction Attribute in Network Dataset or “NA”|Network Analyst Boolean restriction variable
delimiter|“ – “|PlanId delimiter separating floor name from number
accessible|YES or NO|Whether an accessible attribute is included in the published feature class
indoorPlans|“mapServiceLayer” or “imageServiceLayer” or “NA”|Type of service supporting indoor plans (map service or image service)
host|“192.168.1.1” or “maps.esri.com”|Arcgis server network address
mapService|MapServer Url|Address of Map Service
planService|MapServer Url|Address of image or map service that hosts indoor plans (Can be the same as mapService if using map services)
networkService|Network Service Url|Address of published networked analyst
topo|Mapserver Url|Topographic basemap service
satellite|Mapserver Url|Satellite basemap service
roomServiceLayer| layer index|Room layer used to populate list of rooms
buildingServiceLayer |“NA” or  layer index|Table of long building names lookup
stackLayer|“NA” or layer index|Feature service layer of library stacks
startLayerRange|layer index|Start of layers in planService  (Only needed if not using an image service for floorplans)
endLayerRange|layer index|End of layers in planService (Only needed if not using an image service for floorplans)
