# SYSTEM APP BGWORKERS
# --------------------------------------------------------------------------

express = require "express"
fs = require "fs"
lodash = require "lodash"

# Environment variables.
env = process.env
vcap = env.VCAP_SERVICES
vcap = JSON.parse(vcap) if vcap?

# Global variables.
machines = []
hosts = []
batchMachines = ""
batchHosts = ""


# WEB SERVER
# --------------------------------------------------------------------------

# Create the express app.
app = express()

# Get IP and port from environment variables.
ip = env.OPENSHIFT_INTERNAL_IP or env.OPENSHIFT_NODEJS_IP or env.IP
port = env.OPENSHIFT_INTERNAL_PORT or env.OPENSHIFT_NODEJS_PORT or env.VCAP_APP_PORT or env.PORT or 8080

# Create server and bind Socket.IO to the app and listen to connections.
# Port is defined on the [Server Settings](settings.html).
server = require("http").createServer app

# Server listen.
if ip? and ip isnt ""
    server.listen ip, port
else
    server.listen port

# Set routes.
app.get "/", (req, res) ->
    html = "<div>#{batchMachines}</div> <div>#{batchHosts}</div>"

    fs.readFile "./index.html", (err, data) ->
        html = data.toString().replace "[[output]]", html
        res.send html


# MYSQL DATA
# --------------------------------------------------------------------------

# Set MySQL prefs.
mysql = require "mysql-native"
mysqlDetails = vcap["mysql-5.1"][0]["credentials"]

# Set MySQL object.
db = require("mysql-native").createTCPClient mysqlDetails.host, mysqlDetails.port
db.auto_prepare = true
db.auth mysqlDetails.name, mysqlDetails.username, mysqlDetails.password

# Helper to update host data.
updateHosts = ->
    console.warn "updateHosts()"
    batchHosts = ""

    # For each machine, 30% chances of not updating host data.
    for h in hosts
        if Math.random() > 0.3

            # CPU load between 0 and 2. If more than 1, recalculate once more.
            cpuLoad = 2 * Math.random()
            cpuLoad = 2 * Math.random() if cpuLoad > 1
            cpuLoad = cpuLoad.toFixed 2

            # Free RAM changes by up to 50%. If reaches less than 10% total, get a new random value.
            ramFree = h["ram_free"] * Math.random() * 0.5
            if Math.random() > 0.5
                ramFree = h["ram_free"] + ramFree
            else
                ramFree = h["ram_free"] - ramFree
            ramFree = h["ram_total"] * Math.random() if ramFree < h["ram_total"] / 10
            ramFree = ramFree.toFixed 2

            # Free disk space changes by up to 50%. If reaches less than 10% total, get a new random value.
            diskFree = h["disk_free"] * Math.random() * 0.5
            if Math.random() > 0.5
                diskFree = h["disk_free"] + diskFree
            else
                diskFree = h["disk_free"] - diskFree
            diskFree = h["disk_total"] * Math.random() if ramFree < h["ram_total"] / 10
            diskFree = diskFree.toFixed 2

            # Disk load between 0 and 1. If more than 80%, recalculate once more.
            diskLoad = 1 * Math.random()
            diskLoad = 1 * Math.random() if diskLoad > 0.8
            diskLoad = diskLoad.toFixed 2

            # Set random requests per second, changing by up to 30%, and if more than 1000, recalculate.
            requestsSec = h["requests_sec"] * Math.random() * 0.3
            if Math.random() > 0.5
                requestsSec = h["requests_sec"] + requestsSec
            else
                requestsSec = h["requests_sec"] - requestsSec
            requestsSec = 1000 * Math.random() if requestsSec > 1000

            # Add to batch host update.
            q = "UPDATE cmdb_host SET cpu_load='#{cpuLoad}', ram_free='#{ramFree}', disk_free='#{diskFree}', disk_load='#{diskLoad}', requests_sec='#{requestsSec}' WHERE id = #{h.id};"
            batchHosts += q + "\n";
        else
            batchMachines += "Skipped host #{h.id};\n";

    # Execute batch update for machines.
    db.query batchHosts

# Helper to update machine data.
updateMachines = ->
    console.warn "updateMachines()"
    batchMachines = ""

    machines = lodash.unique hosts, "machine_id"

    # For each machine, 30% chances of not updating machine data.
    for m in machines
        if Math.random() > 0.3

            # CPU load between 0 and 2. If more than 1.5, recalculate once more.
            cpuLoad = 3 * Math.random()
            cpuLoad = 3 * Math.random() if cpuLoad > 1.5
            cpuLoad = cpuLoad.toFixed 2

            # Disk load between 0 and 1. If more than 80%, recalculate once more.
            diskLoad = 1 * Math.random()
            diskLoad = 1 * Math.random() if diskLoad > 0.8
            diskLoad = diskLoad.toFixed 2

            # Add to batch machine update.
            q = "UPDATE cmdb_machine SET cpu_load='#{cpuLoad}', disk_load='#{diskLoad}' WHERE id = #{m.machine_id};"
            batchMachines += q + "\n";
        else
            batchMachines += "Skipped machine #{m.machine_id};\n";

    # Execute batch update for machines.
    db.query batchMachines

    # Now update hosts.
    updateHosts()

# Randomize CPU, RAM and Disk data on the CMDB demo database.
randomizeCmdbData = ->
    hosts = []
    machines = []

    query = db.query("SELECT H.*,
              M.cpu_load AS machine_cpu_load,
              M.ram_total AS machine_ram_total,
              M.disk_total AS machine_disk_total,
              M.disk_load AS machine_disk_load
              FROM cmdb_machine M, cmdb_host H WHERE M.id = H.machine_id")

    # Populate hosts collection and start updating on end.
    query.on "row", (r) -> hosts.push r
    query.on "end", -> updateMachines()


# SCHEDULED TASKS
# --------------------------------------------------------------------------
console.warn "Starting scheduled tasks..."
setInterval randomizeCmdbData, 5000