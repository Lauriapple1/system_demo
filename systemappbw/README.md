# System App by Zalando - Readme

**Official homepage:** **http://systemapp.io**

The System App is a sleek, smart and open-source IT mapping and monitoring tool by Zalando.
Please note that it is still in BETA so some features are not yet fully implemented,
although it's quite usable in its current state.

Full documentation can be found under the `/docs` directory of the app.
The final 1.0.0 version is expected to be ready by Summer 2013.

#### What's still not ready for prime time?

##### Sooner than later
- Users and roles. Basic HTTP authentication is done and ready, LDAP to follow.
- Admin area to manage server, settings and users directly on the browser.
- Better and smarter auto completion when editing shape labels.
- Auto completion when editing Audit Event rules (just like on shape labels).
- Performance improvements on complex maps. SVG is slow, so we'll tweak our implementation to
  minimze DOM queries and whenever possible use hardware accelerated features on rendering.

##### Not so soon
- Better and more stable sync of data using Socket.IO instead of AJAX calls.
- Self-healing features - app will self diagnose in case too many errors are triggered.
- External API with HTTP webhooks. The current API is for internal use only.
- Undo and redo of actions especially when editing maps.
- Support for multiple users editing a map at the same time, or at least map locking when there's
  someone editing it already.

## Installation

Felling lazy? Simply run the `./install.sh` script and it will try to do all the hard work for you.
It should work on Linux and OS X.

1.  Download the `./install.sh` and save it on the directory where you want to install the System App.
    `$ curl https://raw.github.com/zalando/system/master/install.sh`
    or
    `$ wget https://raw.github.com/zalando/system/master/install.sh`
2.  Make it executable.
    `$ chmod +x install.sh`
3.  Run it and hope for the best :-)
    `$ ./install.sh`

The script should tell you what's missing and ask if you want to install the missing dependencies.

### Installing manually

If the install script doesn't work or if you prefer to do stuff manually, please make sure
you have installed on your system:

- Node.js (http://nodejs.org)
- MongoDB (http://mongodb.org)
- ImageMagick (http://www.imagemagick.org)

To install Node.js on Linux:
http://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager

MongoDB can be downloaded from:
http://www.mongodb.org/downloads

ImageMagick is necessary to generate map thumbnails. The app will actually run without it,
but then you won't have a "preview" of each map on the start screen.
To download ImageMagick:
http://www.imagemagick.org/script/binary-releases.php

### Required Node.js modules

Check the `package.json` file for details on dependencies.

The easiest way to get these is by running NPM update:

`$ npm update`

Please note that all modules will be installed locally under the `node_modules` directory.

### Avoiding MongoDB installation

If you don't want to install and configure MongoDB locally, we suggest creating a free online
database at http://mongolab.com or http://mongohq.com. The connection string will be something like:

`mongodb://your_user:your_password@ds033187.mongolab.com:33187/your_database?auto_reconnect`

## Configuring the server

All basic server configuration settings are located on the file `server/settings.coffee`.
If you want to override settings, please create or edit the `settings.json` file with
the properties and values to be overriden.

Detailed instructions are available on on the top of the `server/settings.coffee` file.

The following settings will need your attention:

##### Settings.General
- `appTitle` - The app title, default is "System App". You can use something like "MyCompany System".
- `debug` - Enable debbuging logs. This should be set to false before you deploy the app to production!

##### Settings.Database
- `connString` - The MongoDB connection string. Default is host "localhost", database "systemapp".

##### Settings.Web
- `port` - The port used by the Node.js server, default is 3003.
- `paas` - Set to true if you're deploying to common PaaS services. More info below.

##### Settings.Security
- `port` - The port used by the Node.js server, default is 3003.
- `userPasswordKey` - The secret key/token used to encrypt passwords on the database.

##### Deploying to PaaS
The System App can be easily deployed to AppFog, OpenShift and Heroku. The only requirement is
that you set `Settings.Web.paas` to true (it is true by default). In this case we'll override a few
settings to cope with the PaaS environment. For example:
- the web `port` will be automatically set so it doesn't matter what value you have entered.
- if your app on AppFog has a MongoDB bound to it, the `connString` will be automatically set.
- it will use [Logentries](http://logentries.com) for logging if you have enabled it on your AppFog account.

## Starting the server

To start the System App:

`$ node index.js`

This will start Node.js under the port 3003 (or whatever port you have set on the server settings).

### Production vs. Debugging

By default Node.js will run in "Debug mode". If you're deploying and running on production,
you must set the `NODE_ENV` to "production" to avoid having all the debugging statements
logged to the console. Putting it simple:

`$ NODE_ENV=production node index.js`

### Running the server forever

If you want the server to run like a service (so it restarts itself in case of crash / error / termination)
we recommend using the node module **forever**. You can install it using NPM like this:

`$ sudo npm install -g forever`

To start the SYstem App using *forever*, run it under the app root folder:

`$ forever start -c node index.js`

## Code implementation

To make things easier to understand:

* All customizable client settings are available on the *SystemApp.Settings* object, at the `/assets/js/settings.coffee` file.
* Terms, validation and error messages are set under the *SystemApp.Messages* object, file `/assets/js/messagess.coffee`.
* URL routes are set under a *SystemApp.Routes* object, file `/assets/js/routes.coffee`.

The System App uses the latest version of [Backbone](http://http://backbonejs.org/) to implement models, collections and views.
The maps are implemented using SVG and handled by [Raphaël](http://raphaeljs.com/).

Having experience with the aforementioned libraries is not strictly necessary, but highly desirable in
case you want to customize the System App's code.

### Models and collections

Models won't inherit directly from Backbone.Model. Instead we're using our own `SystemApp.BaseModel`,
which extends Backbone's model with special methods like `save`, `generateId`, etc. Same thing
for collections, which should inherit from `SystemApp.BaseCollection`.

All models are located under the folder `/assets/js/models`, and each model has its own specific collection
implemented at the end of the same file.

### Views

The views are composed of:

* HTML template using [Jade](http://jade-lang.com/), folder `/views`.
* CSS styles using [Stylus](http://learnboost.github.com/stylus/), folder `/assets/css`.
* View controllers implemented with CoffeeScript, folder `/assets/js/view`.

Just like models and collections, the app has its own `SystemApp.BaseView`
which extends Backbone's view with extra helpers and utilities.

### Database

The System App uses MongoDB to store its data, having the following collections:

* *map* - stores all maps (Map model) including their referenced shapes (Shape model) and links (Link model).
* *entity* - store entity schemas (EntityDefinition model) and data (EntityObject model).
* *auditdata* - store all audit data definitions and data (AuditData model).
* *auditevent* - store all audit events and alerts (AuditEvent model).
* *variable* - stores custom JS variables (Variable model) created by users.
* *user* - stores uses (User model) and their associated roles.
* *log* - logs all updates, inserts and deletes on the collections above.

The "log" collection is there for increased security and damage control. All updates, inserts
and deletions are logged there, and these records stay saved for 2 hours by default - you can
change this setting on the server's `settings.json` or `settings.coffee` file.

## Need help?

Issues should be posted on the Issues section on our GitHub project page: https://github.com/zalando/system/issues

*Have fun!*