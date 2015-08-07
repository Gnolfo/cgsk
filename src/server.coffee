express = require("express")
http = require('http')
# https = require('https')
# fs = require('fs')
path = require("path")
# favicon = require("serve-favicon")
logger = require("morgan")
cookieParser = require("cookie-parser")
bodyParser = require("body-parser")
mysql = require('mysql')
Q = require('q')
SHA256 = require("crypto-js/sha256")
session = require("client-sessions")
hbs = require('hbs')
json = require('hbs-json')
express = require('express')
exphbs  = require('express-handlebars')
debug = require("debug")("react-express-template")
require("babel/register")

dist = path.join(__dirname, '/../dist')
assets = path.join(__dirname, '/../assets')
app = express()
# enable if you have a favicon
# app.use favicon("#{dist}/favicon.ico")
app.use logger("dev")
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cookieParser()
app.use express.static(dist)
app.use express.static(assets) 


# 150 day expiration
app.use session( cookieName: "session", secret: process.env.SESSION_SALT, duration: 150 * 24 * 60 * 60 * 1000)


app.set "port", process.env.PORT or 3000

app.engine 'handlebars', exphbs()
app.set 'view engine', 'handlebars'
app.set 'views', __dirname

hbs.registerHelper 'json', json


#
# CORS support
#
# app.all '*', (req, res, next) ->
#   res.header("Access-Control-Allow-Origin", "*")
#   res.header("Access-Control-Allow-Headers", "X-Requested-With")
#   next()

pool = mysql.createPool(
    host: process.env["DATABASE_HOST"], 
    user: process.env["DATABASE_USER"], 
    password: process.env["DATABASE_PASS"], 
    database: process.env["DATABASE_DB"],
    waitForConnections: true,
    connectionLimit: 10)

closeDB = ->
  dbConnected = false
  dbConnection.end()

dbQuery = (query, cb) ->  
  debug = false
  console.log 'running: '+query if debug
  pool.query query, (err,results) ->
    console.log 'ran: '+query if debug
    cb err, results

oldDbQuery = (query,cb) ->
  pool.getConnection (err, conn) ->
    throw err if err
    conn.query query, (err, results) ->
      cb err, results
      conn.release()

dbGetCharacters = () ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM characters", deferred.makeNodeResolver()
  deferred.promise

dbGetLists = () ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM lists", deferred.makeNodeResolver()
  deferred.promise

dbGetLogs = () ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM logs order by timestamp desc", deferred.makeNodeResolver() 
  deferred.promise

dbGetBosses = ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM bosses", deferred.makeNodeResolver()
  deferred.promise

dbGetRaidData = ->
  deferred = Q.defer()
  dbQuery "SELECT b.id, b.name, b.position, b.avatar_url, i.item_id, i.list_id FROM bosses b JOIN items i on i.boss_id=b.id", deferred.makeNodeResolver()
  deferred.promise

# 
# Auth Queries
#
dbAuthUser = (username, password) ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM users where username = "+mysql.escape(username)+" and password="+mysql.escape(password), deferred.makeNodeResolver()
  deferred.promise    

dbCheckUser = (id) ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM users where id = "+mysql.escape(id),  deferred.makeNodeResolver()
  deferred.promise    
   
# 
# Raid Queries 
# 

dbStartRaid = ->
  deferred = Q.defer()
  dbLogStart()
  dbQuery "INSERT INTO raids (time_start) VALUES (now())",  deferred.makeNodeResolver()
  deferred.promise  

dbGetActives = (raid_id) ->
  raid_id = mysql.escape raid_id
  deferred = Q.defer()
  dbQuery "select * from raids_characters where raid_id=#{raid_id}", deferred.makeNodeResolver()
  deferred.promise  

dbEndRaid = (raid_id) ->
  raid_id = mysql.escape raid_id
  deferred = Q.defer()
  dbLogEnd()
  dbQuery "UPDATE raids set time_end=NOW() where id=#{raid_id}",  deferred.makeNodeResolver()
  deferred.promise  

dbGetOpenRaid = ->
  deferred = Q.defer()
  dbQuery "SELECT * FROM raids where time_end is null order by time_start limit 1",  deferred.makeNodeResolver()
  deferred.promise  

dbAddRaiders = (raid_id, characters) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  inserts = characters.map (v) ->
    dbLogAddRem v, true
    "(#{raid_id},"+(mysql.escape v)+")"
  sql = "insert into raids_characters (raid_id, character_id) VALUES "+inserts.join ",\n"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbRemRaiders = (raid_id, characters) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  list = characters.map (v) ->
    dbLogAddRem v, false
    mysql.escape v
  sql = "delete from raids_characters WHERE raid_id="+raid_id+" and character_id in ("+(inserts.join ",")+")"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise 

# 
# Logging Queries 
# 

dbLogStart = ->
  deferred = Q.defer()
  sql = "insert into logs (action, timestamp) VALUES ('start', NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbLogEnd = ->
  deferred = Q.defer()
  sql = "insert into logs (action, timestamp) VALUES ('end', NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise    

dbLogAddRem = (character_id, add) ->
  character_id = mysql.escape character_id
  deferred = Q.defer()
  action = mysql.escape (if add then 'add' else 'rem')
  sql = "insert into logs (action, subject_id, timestamp) VALUES ("+action+","+character_id+", NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbLogBoss = (boss_id) ->
  boss_id = mysql.escape boss_id
  deferred = Q.defer()
  sql = "insert into logs (action, subject_id, timestamp) VALUES ('boss',"+boss_id+", NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbLogLoot = (raid_id, character_id, item_id) ->
  raid_id = mysql.escape raid_id
  character_id = mysql.escape character_id
  item_id = mysql.escape item_id
  deferred = Q.defer()
  sql = "insert into logs (action, subject_id, object_id, timestamp) VALUES ('loot',"+character_id+","+item_id+", NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

#
# Tricky query to get all active people (including looter) who will be affected in the lists from a loot suicide
#

dbGetActivesForSuicide = (raid_id, list_id, character_id) ->
  raid_id = mysql.escape raid_id
  list_id = mysql.escape list_id
  character_id = mysql.escape character_id
  deferred = Q.defer()
  sql = "select l.* from lists looter
    join lists l on l.list_id=#{list_id} and l.position >= looter.position 
    join raids_characters rc on rc.character_id=l.character_id
    where 
    looter.list_id=#{list_id} 
    and rc.raid_id=#{raid_id}
    and looter.character_id=#{character_id}
    order by l.position asc "
  dbQuery sql, deferred.makeNodeResolver()
  deferred.promise  

#
# Query to move around character positions in a list 
# new_ranks is an array of character_id/position pairs that reflect where they should move to
# anyone not in new_ranks will keep their position
#

dbChangeRankings = (list_id, new_ranks) ->
  list_id = mysql.escape list_id
  updates = new_ranks.map (v) ->
    deferred = Q.defer()
    position = mysql.escape v.position
    character_id = mysql.escape v.character_id
    dbQuery "update lists set position=#{position} where list_id=#{list_id} and character_id=#{character_id}", deferred.makeNodeResolver()
    deferred.promise
  Q.all updates


#
# Utility
# 

assembleListsForFrontend = (list_rows) ->
  list_rows.reduce (pv, cv) ->
        pv[cv.list_id] = {} unless typeof pv[cv.list_id] is 'object'
        pv[cv.list_id][cv.position] = cv
        pv
      , {}




# app.use (req,res,next) ->
# user_id = req.session?.user?.id
#  req.user = req.session.user if user_id? and dbCheckUser user_id
#  next()

authRequired = (req,res,next)  ->
  if req.session?.user?
    next()
  else
    res.send(error: 'auth')

app.get '/test', (req,res) ->
  dbGetOpenRaid()
  .then (raid) ->
    raid_id = if raid.length > 0 then raid.pop().id else false
    res.send(raid:raid_id)
 

app.post '/login', (req,res) ->
  username = req.body.username
  password = SHA256 req.body.password
  dbAuthUser username, password.toString()
    .then (users) ->
      success = users.length > 0
      if success
        cookie_user = users.shift()
        delete cookie_user.password
        req.session = user:cookie_user        
        res.locals = user:cookie_user
      res.send(success: success)

app.post '/loot', (req,res) ->
  list_id = req.body.list_id
  character_id = req.body.character_id
  item_id = req.body.item_id
  raid_id = req.body.raid_id
  dbGetActivesForSuicide(raid_id, list_id, character_id)
    .then (old_ranks) ->
      # The actual suicide logic, first sort the rankings of actives by position (looter should be first thanks to getActivesForSuicide)
      old_ranks.sort (a,b) ->
        a.position - b.position
      # next two lines destructure the looter from the remaining actives and put them at the bottom of actives in transition_ranks
      # essentially the heart of SK in two lines of code
      [looter, actives...] = old_ranks
      transition_ranks = [actives..., looter]
      # But now we have to stitch the positions back together, essentially charcters draw from transition and position draws from old_ranks
      # The result is the looter gets the position of the last active, and all actives trade up their position w/ the top active getting the old looter position
      new_ranks = transition_ranks.map (v,i) ->
        position: old_ranks[i].position, character_id: v.character_id
      dbChangeRankings list_id, new_ranks
      .then ->
        dbLogLoot raid_id, character_id, item_id
        dbGetLists()
        .then (rankings) ->
          res.send lists: (assembleListsForFrontend rankings)


app.post '/start', (req,res) ->
  dbGetOpenRaid()
  .then (raid) ->
    if raid.length > 0
      res.status(400).send error: 'an open raid already exists' 
    else
      characters = req.body.characters
      dbStartRaid()
      .then (results) ->
        raid_id = results.insertId
        dbAddRaiders(raid_id, characters)
        .then ->
          res.send(raid_id: results.insertId)

app.post '/end', (req,res) ->
  raid_id = req.body.raid_id
  dbEndRaid raid_id
  .then ->
    res.send success:true

app.post '/boss', (req,res) ->
  boss_id = req.body.boss_id
  dbLogBoss()
  .then ->
    res.send success:true

app.post '/add', (req,res) ->
  raid_id = req.body.raid_id
  characters = req.body.characters
  dbAddRaiders(raid_id, characters)
  .then ->
    res.send success:true

app.post '/rem', (req,res) ->
  raid_id = req.body.raid_id
  characters = req.body.characters
  dbRemRaiders(raid_id, characters)
  .then ->
    res.send success:true


app.get '/', (req, res) ->
  Q.all [dbGetCharacters(), dbGetLists(), dbGetLogs(), dbGetRaidData(), dbGetOpenRaid(), dbGetActives()]
    .spread (characters, lists, logs, raid_data, open_raid, active_raiders) -> 
      characters = characters.reduce (pv, cv) ->
        pv[cv.id] = cv
        pv
      , {}
      lists = assembleListsForFrontend lists  
      raid_data = raid_data.reduce (pv,cv) ->
        pv[cv.id] = (id: cv.id, name: cv.name, avatar_url: cv.avatar_url, items:[], position:cv.position) unless pv[cv.id]?
        pv[cv.id].items.push(item_id: cv.item_id, list_id: cv.list_id)
        pv
      ,{}
      raid_id = if open_raid.length > 0 then open_raid.pop().id else false
      if raid_id != false
        dbGetActives(raid_id)
        .then (raiders) ->
          active_raiders = raiders.map (v) -> id: v.character_id, active: true
          res.render 'index.hbs', (characters:characters, lists: lists, logs: logs, raid_data: raid_data, raid_id: raid_id, active_raiders: active_raiders)
      else
        res.render 'index.hbs', (characters:characters, lists: lists, logs: logs, raid_data: raid_data, raid_id: raid_id, active_raiders: [])

## catch 404 and forwarding to error handler
app.use (req, res, next) ->
  err = new Error("Not Found")
  err.status = 404
  next err

## error handlers

# development error handler
# will print stacktrace
if app.get("env") is "development"
  app.use (err, req, res, next) ->
    res.status err.status or 500
    res.send(message: err.message, status: err.status, stack: err.stack)

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) ->
  res.status err.status or 500
  res.send(message: err.message)


#
# HTTPS support
#
# options = key: fs.readFileSync('key.pem'), cert: fs.readFileSync('cert.pem')
# httpsServer = https.createServer(options, app)
# httpsServer.listen app.get("port"), ->
#   debug "Express https server listening on port " + httpsServer.address().port

server = http.createServer(app)
server.listen app.get("port"), ->
  debug "Express server listening on port " + server.address().port
