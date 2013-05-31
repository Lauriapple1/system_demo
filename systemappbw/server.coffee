# SYSTEM APP BGWORKERS
# --------------------------------------------------------------------------

class Bw

    express = require "express"
    fs = require "fs"
    lodash = require "lodash"
    moment = require "moment"
    mongo = require "mongoskin"

    # Environment variables.
    env = process.env
    vcap = env.VCAP_SERVICES
    vcap = JSON.parse(vcap) if vcap?

    # Global variables.
    machines = []
    hosts = []
    batchMachines = ""
    batchHosts = ""
    lastCmdbUpdate = false
    lastMongoDelete = false


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
        html = "<div>Last CMDB randomize: #{lastCmdbUpdate}</div> <div>#{batchMachines}</div> <div>#{batchHosts}</div> <br /><hr /> <div><strong>User maps last cleaned:</strong> #{lastMongoDelete}.</div>"

        fs.readFile "./index.html", (err, data) ->
            html = data.toString().replace "[[output]]", html
            res.send html


    # MYSQL DATA
    # --------------------------------------------------------------------------

    # Set MySQL prefs.
    mysql = require "mysql-native"
    mysqlDetails = vcap["mysql-5.1"][0]["credentials"]

    # Set MySQL object.
    mysqlDb = require("mysql-native").createTCPClient mysqlDetails.host, mysqlDetails.port
    mysqlDb.auto_prepare = true
    mysqlDb.auth mysqlDetails.name, mysqlDetails.username, mysqlDetails.password

    # Helper to update host data.
    updateHosts = ->
        console.warn "updateHosts()"
        batchHosts = ""

        # For each machine, 10% chances of not updating host data.
        for h in hosts
            if Math.random() > 0.1

                statusId = h["status_id"]
                statusRandom = Math.random()

                # If host is available, 2% chances of putting in under maintenance.
                if h["status_id"] is 5
                    if statusRandom > 0.17 and statusRandom < 0.19
                        statusId = 6

                # If host is in maintenance, 40% chances of putting it available.
                else if h["status_id"] is 6
                    if statusRandom > 0.4 and statusRandom < 0.8
                        statusId = 5

                # Only update hosts if they're status 4, 5 or 6
                if statusId >= 4 and statusId <= 6
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
                    ramFree = h["ram_total"] * Math.random() if ramFree < h["ram_total"] / 10 or ramFree >= h["ram_total"]
                    ramFree = ramFree.toFixed 2

                    # Free disk space changes by up to 50%. If reaches less than 10% total, get a new random value.
                    diskFree = h["disk_free"] * Math.random() * 0.5
                    if Math.random() > 0.5
                        diskFree = h["disk_free"] + diskFree
                    else
                        diskFree = h["disk_free"] - diskFree
                    diskFree = h["disk_total"] * Math.random() if diskFree < h["disk_total"] / 10 or diskFree >= h["disk_total"]
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
                    q = "UPDATE cmdb_host SET cpu_load='#{cpuLoad}', ram_free='#{ramFree}', disk_free='#{diskFree}', disk_load='#{diskLoad}', requests_sec='#{requestsSec}', status_id='#{statusId}' WHERE id = #{h.id};"
                    batchHosts += q + "\n";
            else
                batchHosts += "# Skipped host #{h.id};\n";

        # Execute batch update for machines.
        mysqlDb.query batchHosts

        lastCmdbUpdate = moment().format "DD.MM.YYYY hh:mm:ss"

    # Helper to update machine data.
    updateMachines = ->
        console.warn "updateMachines()"
        batchMachines = ""

        machines = lodash.unique hosts, "machine_id"

        # For each machine, 20% chances of not updating machine data.
        for m in machines
            if Math.random() > 0.2

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
                batchMachines += "# Skipped machine #{m.machine_id};\n";

        # Execute batch update for machines.
        mysqlDb.query batchMachines

        # Now update hosts.
        updateHosts()

    # Randomize CPU, RAM and Disk data on the CMDB demo database.
    randomizeCmdbData = ->
        hosts = []
        machines = []

        query = mysqlDb.query("SELECT H.*,
                  M.cpu_load AS machine_cpu_load,
                  M.ram_total AS machine_ram_total,
                  M.disk_total AS machine_disk_total,
                  M.disk_load AS machine_disk_load
                  FROM cmdb_machine M, cmdb_host H WHERE M.id = H.machine_id")

        # Populate hosts collection and start updating on end.
        query.on "row", (r) -> hosts.push r
        query.on "end", -> updateMachines()


    # MONGODB DATA
    # --------------------------------------------------------------------------

    # Set MongoDB connection.
    connString = vcap["mongodb-1.8"]
    connString = connString[0]["credentials"]
    connString = "mongodb://#{connString.hostname}:#{connString.port}/#{connString.db}"
    mongoDb = mongo.db connString, {fsync: false}

    # Delete demo maps created by users older than 2 hours.
    deleteMaps = ->
        minDate = moment().subtract "h", 2
        options = {"dateCreated": {"$lt": minDate}, "isReadOnly": false}
        mongoDb.collection("map").remove options, (err, result) =>
            if err?
                lastMongoDelete = JSON.stringify err
            else
                lastMongoDelete = moment().format "DD.MM.YYYY hh:mm:ss"

            console.warn "deleteMaps()", err, result


    # SCHEDULED TASKS
    # --------------------------------------------------------------------------
    console.warn "Starting scheduled tasks..."
    setInterval randomizeCmdbData, 3000
    setInterval deleteMaps, 60000


# Singleton.
Bw.getInstance = ->
    @instance = new Bw() if not @instance?
    return @instance

module.exports = exports = Bw.getInstance()