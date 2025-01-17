# TracerouteMap
## About
lua script that uses tshark (command line wireshark) and python to read a pcapng file and extract geoIP locations, then runs traceroute on every ipv4 address identified, saving each route to json. Then, a python script is used to convert this data into geojson form that is then fed into a static html page created using QGIS.
## Prerequisites
- Operating system that has a UNIX compatible
- lua 5.4 & lualanes,
- python 3.11
- tshark with configured geoIP file location. the easiest way to do this is through wireshark (see [here](https://wiki.wireshark.org/HowToUseGeoIP))
- A pcapng file with user read access in terminal

Todo: add self contained release which only requires configured tshark install
Todo: add windows support(only minimal changes are required

## Usage
in

## Limitations
- threading: many traceroutes have to be ran as there are many addresses present in the average capture file, running the script will take a few minutes if >100 IP addresses. From experimentation with lualanes, more than 10 traceroutes running concurrently can affect results and causes slowdowns on my device
- traceroute: traceroute is an imperfect tool, alot of the "hops" can go undiscovered, making the . Additionally, multiple routes for an IP address used for loadbalancing are ignored, with only the first IP address given in each hop being noted
- map display: the QGIS plugin used to convert the map to static html is incompatible with some QGIS features and so for now the visualisation uses no blending. Additionally
