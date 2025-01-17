import geoip2.database
import json
import geojson
import copy
import os
import sys

data = []
with open("raw.json") as f:
    data = json.load(f)["entries"]
newjson = []

with geoip2.database.Reader(os.path.join(sys.argv[1], "GeoLite2-City.mmdb")) as reader:
    for i in range(len(data)):
        try:
            response = reader.city(data[i]["ip_address"])
            
            # Validate initial coordinates
            if response.location.latitude is None or response.location.longitude is None:
                continue
            if not (-90 <= response.location.latitude <= 90):
                continue
            if not (-180 <= response.location.longitude <= 180):
                continue
                
            data[i]["coordinates"] = [response.location.longitude, response.location.latitude]
            data[i]["georoute"] = []
            
            # Process route
            for j in range(1, len(data[i]["route"])):
                try:
                    route_response = reader.city(data[i]["route"][j])
                    
                    # Validate route coordinates
                    if route_response.location.latitude is None or route_response.location.longitude is None:
                        continue
                    if not (-90 <= route_response.location.latitude <= 90):
                        continue
                    if not (-180 <= route_response.location.longitude <= 180):
                        continue
                        
                    data[i]["georoute"].append([
                        route_response.location.longitude,
                        route_response.location.latitude
                    ])
                except Exception as e:
                    # print(f"Route error: {e}")
                    continue
                    
            # Add final coordinates if needed
            if data[i]["ip_address"] != data[i]["route"][-1]:
                data[i]["georoute"].append(data[i]["coordinates"])
                
            # Create GeoJSON feature if we have enough points
            if len(data[i]["georoute"]) > 1:
                newjson.append(geojson.Feature(
                    geometry=geojson.LineString(data[i]["georoute"]),
                    properties={
                        "ip_address": data[i]["ip_address"],
                        "total_bytes": int(data[i]["total_bytes"])
                    }
                ))
                
        except Exception as e:
            # print(f"Main loop error: {e}")
            continue
geoformat = geojson.FeatureCollection(newjson)
#loading the paths_1.js for qgis
with open(os.path.join('mapRendering', "data", 'paths_1.js'), 'w', encoding='utf-8') as f:
    placeholder = geojson.dumps(geoformat)
    yuh = json.loads(placeholder)
    #"name":"paths_1","crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}},
    yuh["name"] = "paths_1"
    yuh["crs"] = {"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}}
    more = json.dumps(yuh)
    more = "var json_paths_1 = " + more
    f.write(more)

#loading the vertices_2.js
with open(os.path.join('mapRendering', "data", 'Vertices_2.js'), 'w', encoding='utf-8') as f:
    placeholder = geojson.dumps(geoformat)
    yuh = json.loads(placeholder)
    yuh["name"] = "Vertices_2"
    yuh["crs"] = {"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}}
    new = copy.deepcopy(yuh)
    new["features"] = []
    i = 1
    for j in range(len(yuh["features"])):
        x=yuh["features"][j]
        for k in range(len(yuh["features"][j]["geometry"]["coordinates"])):
            new["features"].append({"type":"Feature","properties":{"fid":i
                                            ,"ip_address":x["properties"]["ip_address"]
                                            ,"total_bytes":float(x["properties"]["total_bytes"])
                                            ,"vertex_index":k,"vertex_part":0.0,"vertex_part_index":k,"distance":0.0,"angle":90.0}
                                            ,"geometry":{"type":"Point","coordinates":yuh["features"][j]["geometry"]["coordinates"][k]}})
            i+=1
    more = json.dumps(new)
    more = "var json_Vertices_2 = " + more
    f.write(more)




