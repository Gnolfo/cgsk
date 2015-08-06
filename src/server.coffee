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
Q = require('Q')
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

pool = mysql.createPool(host: process.env["DATABASE_HOST"], user: process.env["DATABASE_USER"], password: process.env["DATABASE_PASS"], database: process.env["DATABASE_DB"])

closeDB = ->
  dbConnected = false
  dbConnection.end()

dbQuery = (query, cb) ->
  pool.getConnection (err, conn) ->
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
  dbQuery "INSERT INTO raids (time_start) VALUES (now())",  deferred.makeNodeResolver()
  deferred.promise  

dbAddRaiders = (raid_id, characters) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  characters = [characters] unless typeof characters == 'Array'
  inserts = characters.map (v) ->
    "("+raid_id+","+mysql.escape v.id+")"
  sql = "insert into raid_characters (raid_id, character_id) VALUES "+inserts.join ",\n"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbRemRaiders = (raid_id, characters) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  characters = [characters] unless typeof characters == 'Array'
  list = characters.map (v) ->
    mysql.escape v.id
  sql = "delete from raid_characters WHERE raid_id="+raid_id+" and character_id in ("+inserts.join ","+")"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbKillBoss = (raid_id, boss_id) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  boss_id = mysql.escape boss_id
  sql = "isert into logs (action, subject_id, timestamp) VALUES ('boss',"+raid_id+", NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbLoot = (raid_id, character_id, item_id) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  boss_id = mysql.escape boss_id
  character_id = mysql.escape character_id
  sql = "insert into logs (action, subject_id, timestamp) VALUES ('boss',"+boss_id+", NOW() )"
  dbQuery sql,  deferred.makeNodeResolver()
  deferred.promise  

dbGetActivesForSuicide = (raid_id, list_id, character_id) ->
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

dbSuicide = (raid_id, character_id, item_id, list_id) ->
  deferred = Q.defer()
  raid_id = mysql.escape raid_id
  boss_id = mysql.escape boss_id
  character_id = mysql.escape character_id
  dbGetActivesForSuicide(raid_id, mysql.escape list_id, character_id)
    .then (old_ranks) ->
      [looter, actives...] = old_ranks
      transition_ranks = [actives..., looter]
      new_ranks = []
      new_ranks.push position: old_ranks[i].position, character_id: rank.character_id for rank, i in transition_ranks



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
  raid_id = 12
  item_id = 124238
  character_id = 22
  list_id = 1
  list_id = mysql.escape list_id
  raid_id = mysql.escape raid_id
  boss_id = mysql.escape boss_id
  character_id = mysql.escape character_id
  dbGetActivesForSuicide(raid_id, list_id, character_id)
    .then (old_ranks) ->
      old_ranks.sort (a,b) ->
        a.position - b.position
      [looter, actives...] = old_ranks
      transition_ranks = [actives..., looter]
      new_ranks = []
      new_ranks.push position: old_ranks[i].position, character_id: rank.character_id for rank, i in transition_ranks
      res.send old_ranks: old_ranks, transition_ranks: transition_ranks, new_ranks: new_ranks


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

app.post '/loot', authRequired, (req,res) ->
  list_id = req.body.list_id
  character_id = req.body.character_id
  item_id = req.body.item_id
  res.send(message: {list_id: list_id, character_id:character_id, item_id: item_id})

app.post '/start', (req,res) ->
  characters = req.body.characters
  dbStartRaid()
    .then (results) ->
      res.send(raid_id: results.insertId)

app.post '/end', (req,res) ->
  5 

app.post '/boss', (req,res) ->
  5

app.post '/add', (req,res) ->
  5

app.post '/rem', (req,res) ->
  5

app.get '/', (req, res) ->
  Q.all [dbGetCharacters(), dbGetLists(), dbGetLogs(), dbGetRaidData()]
    .spread (characters, lists, logs, raid_data) -> 
      characters = characters.reduce (pv, cv) ->
        pv[cv.id] = cv
        pv
      , {}
      lists = lists.reduce (pv, cv) ->
        pv[cv.list_id] = {} unless typeof pv[cv.list_id] is 'object'
        pv[cv.list_id][cv.position] = cv
        pv
      , {}
      raid_data = raid_data.reduce (pv,cv) ->
        pv[cv.id] = (id: cv.id, name: cv.name, avatar_url: cv.avatar_url, items:[], position:cv.position) unless pv[cv.id]?
        pv[cv.id].items.push(item_id: cv.item_id, list_id: cv.list_id)
        pv
      ,{}
      raid_id = false
      res.render 'index.hbs', (characters:characters, lists: lists, logs: logs, raid_data: raid_data, raid_id: raid_id)

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
