1. Introduction.

These files each contain a json object with at least one component, an object with key
"geojson".  Some files contain a second component, an object with key config which defines
the a legend explaining the colors.  As such the json files can not be view on a pure
geojson viewer like geojson.io.  To extract the geojson, use the script ext_geojson.sh:

	./ext_geojson json-file > /tmp/geojgeon-file

which will create a file w/o any legend that can be view with geojson.io.

2. File descriptions.

src.??.obscured.json	-- Two variable time series.

	A door-dasher agreed to collect data of all of her deliveries in exchange for whatever I
	could learn.  In her first month she delivered from 33 restaurants.  The 5 maps in this
	series show two variables: the number of weeks since the last delievery from a restaurant
	as the pin color with red being within 1 week, and "cooling" down throuhg orange, yellow,
	etc to light gray at 26+ weeks and dark gray at 52+ weeks.  This size of the pin represents
	the total number of visists.  The 01, 05, etc, are the data for the original 33 restaurants
	at months 1, 5, 9, 13 and 17. Click on a pin to see that restauarant's exact data.

sn*.json	-- Seattle neighborhoods and sub-neighborhoods

	From Seattle's data portal, I downloaded their "informal" neighborhoods data.  This data
	divides the city in 119 neighborhoods of which 28 are "water features", ie _small_ creeks,
	inlets, etc, which are not shown on these maps.  Of the remaining 91 neighborhoods, 70
	are part of 16 larger neighborhoods:

		l_neighborhood		# sub neighborhoods
		BALLARD                 5
		BEACON HILL             4
		CAPITOL HILL            5
		CASCADE                 3
		CENTRAL AREA            6
		DELRIDGE                6
		DOWNTOWN                7
		INTERBAY                1
		LAKE CITY               5
		MAGNOLIA                3
		North Beach             1
		NORTHGATE               4
		QUEEN ANNE              4
		RAINIER VALLEY          6
		SEWARD PARK             1
		UNIVERSITY DISTRICT     1
		WEST SEATTLE            8

	Note that the "UNIVERISTY DISTRICT" contains only 1 subneighborhood, also called 
	"University District". (Their caps, not mine.)

	File sn.json shows the 91 non-water neighborhoods 5 colored by adjacency. Some color
	infelicities (North Queen Anne & Fremont, Georgetown & Industrial District_107) but
	as these pairs are not adjacent, still colored correctly.

	File sn.hl.json colors these 91 neighborhoods by containing neighborhood, showing
	the 2-level neighborhood hierarchy.  

	Finally sn.hc.json also groups the neighborhoods by containing, but then recolors
	the subneighborhoods by the 5 colors close related to base color used in sn.hl.json.
	Not every experiment works, but perhaps better colors would help.  Still display of
	hierarchy is important, so I'll keep at it.

53.json		-- Washington state place colored by adjacency.

	The 2016 cartographic boundary file from census.gov recognizes 626 "named places" in
	Washington.  This map resulted from a test of my adjacency code. When this one 
	worked, I created the place adjacency map of the entire US (29854 places) which
	also worked, but at 88M is hard to load, move, etc. so I've left it out the gallery.

tab.json, vg.json, yz.json	-- Tiny "temporary parking" maps.

	Seattle's data portal also include a tsv file of the city's 79316 street parking signs.
	And so I wondered could this be used by food deliverty people to find possible very
	short term parking near restaurants or diners's addresses.

	The three examples are the restaurants Veggie Grill on 4th, Yo! Zushi in Capitol
	Hill and Tableau in Freemont. I wrote a tiny script that takes the address, geocodes
	it, the using an R*tree finds all usable parking places near the address and marks
	them with colored pins on the map.  White pins are 3 min passenger loading zones,
	yellow pins are 30 minute load/unload zone (should pay, but ...), orange pins are
	commercial loading zones (delivery trucks drivers may yell at you and red pins are
	truck loading zones  (Use at own risk)  Finally the purple pin is the address you
	entered
