# SYSTEM APP BGWORKERS
# --------------------------------------------------------------------------

# Create the express app.
app = express()

# Create server and bind Socket.IO to the app and listen to connections.
# Port is defined on the [Server Settings](settings.html).
server = require("http").createServer app
server.listen settings.Web.port