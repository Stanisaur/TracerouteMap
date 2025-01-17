local lanes = require "lanes".configure()
local linda = lanes.linda()
local json = require "dkjson"

local MAXNUMTHREADS = 10

local function getGeoIPfiles()
    local handle = io.popen("tshark -G folders")
    local result = handle:read("*a")
    handle:close()

    -- Split the output into lines
    local lines = {}
    for line in result:gmatch("[^\r\n]+") do
        lines[#lines + 1] = line
    end

    -- Print the last line if there is any output
    if #lines > 0 then
        local filepath = lines[#lines]:match("MaxMind database path:%s*(.+)")
        if filepath then
            print("MaxMind DB folder successfully found: "..filepath)
        end
        return filepath
    else
        print("filepath for MaxMindDB Geo IP info could not be found")
        return ""
    end
end


-- Function to parse the first IP and bytes from the given capture file
local function getFirstIpAndBytes(captureFilename)
    local handle = io.popen("tshark -n -r " .. captureFilename .. " -z endpoints,ip -w test")
    local result = handle:read("*a")
    handle:close()
    
    local addresses = {}
    
    -- Find the first line with IP data
    -- Skip header lines by looking for pattern of IP followed by numbers
    for line in result:gmatch("[^\r\n]+") do
        -- Look for pattern of IP address followed by numbers
        local ip, bytes = line:match("(%d+%.%d+%.%d+%.%d+)%s+%d+%s+(%d+)")
        if ip and bytes then
            table.insert(addresses, {
            ip_address = ip,
            total_bytes = bytes
            })
        end
    end
    
    return addresses
end

local function openHTMLFileWindows()
    os.execute("start " .. "testpage.html")
end

local function openHTMLFileUNIX()
    os.execute("open " .. "test.html")
end

local function get_traceroute_ips(ip_address)
    print("currently processing "..ip_address)
    
    local ip_trace = {}
    
    -- Run traceroute command and capture output
    local handle = io.popen("/usr/sbin/traceroute " .. ip_address)
    if not handle then
        print("os not letting us get a handle bruv")
    end
    local output = handle:read("*a")
    handle:close()


    -- Split output into lines
    if not output then
        print("the output is completely null for some reason"..ip_address)
        return ip_trace
    end
    local iterator = output:gmatch("[^\r\n]+")
    for line in iterator do
        -- Pattern to match IPv4 addresses
        local ip = line:match("%((%d+%.%d+%.%d+%.%d+)%)")
        
        -- Check if we have a match
        if ip then
            table.insert(ip_trace, ip)
        end
    end

    linda:send( "done", true)

    return ip_trace
end

local function writeToJsonFile(filename, data) 
    local str = json.encode({entries = data}, { indent = true })
    local f = io.open(filename, "w")
    f:write(str)
    f:close()
end
--first populate list of ip addresses
-- local ip_list = {"103.152.126.194", "128.0.15.255", "103.31.4.0", "162.158.0.0", "190.93.240.0"}

local params = {...}
local captureFile = params[1]

local geoFolderPath = getGeoIPfiles()
--make thread for every ip that tshark has given us
local thread_template = lanes.gen("string,io,table",get_traceroute_ips)

local data = getFirstIpAndBytes(captureFile)

local routes = {}

local numThreads = 0
for i, entry in ipairs(data) do
    --starting too many threads that execute a process overwhelms the os so we 
    --need to add delay to separate them out
    os.execute("sleep 0.2")
    numThreads = numThreads + 1
    routes[i] = thread_template(entry.ip_address)
    if numThreads >= MAXNUMTHREADS then
        linda:receive(nil, "done")
    end
end

for i, entry in ipairs(data) do
    print("waiting on tracing of ".. entry.ip_address.. " with thread status of " .. routes[i].status)
    if routes[i][1] ~= nil then
        data[i]["route"] = routes[i][1]
    end
end

writeToJsonFile("raw.json", data)

os.execute("python IPs_to_QGIS.py ".. geoFolderPath)

