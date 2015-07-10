window.$ = window.jQuery = require('jquery')
require('semantic-ui-css/semantic')
React = require('react/addons')
Router = require('react-router')
Header = require('./header')

{Route, RouteHandler, DefaultRoute, Link} = Router

Home = React.createClass
  render: ->
    <div className="column">
      <div className="ui segment">
        <h1 className="ui header">
          <span>Get to work!</span>
          <div className="sub header">
            Make sure to check out README.md for development notes.
          </div>
        </h1>
      </div>
    </div>

ListCharacter = React.createClass
  render: -> 
    character_info = character_data[@props.character_id]
    <div className="item">
      <div className="image">
        <img className="ui avatar image" src={"/images/class_"+character_info.class+".jpg"} />
      </div>
      <div className="content">
        <span>{character_info.name}</span>
        <a href="#" rel="item=2828" />
      </div>
    </div>

LogItemLoot = React.createClass
  render: -> 
    <span>{@props.data.character} looted <a href="#" rel={"item-"+@props.data.item} /></span>

LogItemRaidAdd = React.createClass
  render: -> 
    <span>{@props.data.character} added</span>

LogItemRaidRem = React.createClass
  render: -> 
    <span>{@props.data.character} removed</span>

LogItemRaidStart = React.createClass
  render: -> 
    <span>Raid Started :D</span>

LogItemRaidEnd = React.createClass
  render: -> 
    <span>Raid Ended :(</span>

LogItemBoss = React.createClass
  render: -> 
    <span>Boss {@props.data.boss} killed</span>

LogItem = React.createClass
  render: ->
    LogItems = 
      start: 
        el: LogItemRaidStart
        icon: 'thumbs up'
      end: 
        el: LogItemRaidEnd
        icon: 'thumbs down'        
      add: 
        el: LogItemRaidAdd
        icon: 'add user'   
      rem: 
        el: LogItemRaidRem
        icon: 'remove user'
      boss: 
        el: LogItemBoss
        icon: 'heart'
      loot: 
        el: LogItemLoot
        icon: 'bitcoin'
    Item = LogItems[@props.data.type]
    <div className="item">
      <div className="right floated content">
        <div className="metadata">{moment(@props.data.timestamp, "YYYY-MM-DD HH:mm:ss").fromNow()}</div>
      </div>
      <i className={"large middle aligned icon "+Item.icon}></i>
      <div className="content">
        <Item.el data={@props.data}/>
      </div>
    </div>

Log = React.createClass
  getInitialState: ->
    logs: logs
  renderLogItems: -> 
    <LogItem data={data} /> for data in @state.logs 
  render: ->
    <div className="ui middle aligned divided list">
      {@renderLogItems()}
    </div>

List = React.createClass
  getInitialState: ->
    characters: characters
  renderCharacters: -> 
    <ListCharacter character_id={character_id} /> for character_id in @state.characters 
  render: -> 
    <div className="column">
      <div className="ui segment">
        <div className="ui left rail">
          <div className="ui segment">
            Left Rail Content
          </div>
        </div>        
        <div className="ui two column middle aligned very relaxed stackable grid">
          <div className="column">  
            <div className="ui divided selection list">
              {@renderCharacters()}
            </div>
          </div>
          <div className="ui vertical divider">
          </div>
          <div className="center aligned column">
            <Log />
          </div>
        </div>    
      </div>
    </div>

About = React.createClass
  render: ->
    <div className="column">
      <div className="ui segment">
        <h4 className="ui black header">This is the about page.</h4>
      </div>
    </div>

Main = React.createClass
  render: ->
    <div>
      <Header/>
      <div className="ui page grid">
        <RouteHandler {...@props}/>
      </div>
    </div>

routes =
  <Route path="/" handler={Main}>
    <DefaultRoute name="home" handler={Home}/>
    <Route name="about" handler={About}/>
    <Route name="list" handler={List}/>
  </Route>

$ ->
  Router.run routes, Router.HashLocation, (Handler) ->
    React.render(<Handler/>, document.body)

characters = [123,456]

character_data = 
	123: 
	  name: "Tipps"
	  class: "druid"
	456:
	  name: "Hemmlocke"
	  class: "rogue"
  789:
    name: "Wheatstraw"
    class: "druid"

logs = 
  [
    {
      timestamp: '2015-07-09 20:13:45'
      type: 'end'
    },
    {
      timestamp: '2015-07-09 20:13:00'
      type: 'rem'
      character: 789
    },
    {
      timestamp: '2015-07-09 20:12:28'
      type: 'loot'
      item: 124201
      character: 123
    },
    {
      timestamp: '2015-07-09 20:12:28'
      type: 'loot'
      item: 124365
      character: 456
    },
    {
      timestamp: '2015-07-09 20:11:47'
      type: 'boss'
      boss: 95068
    },
    {
      timestamp: '2015-07-09 20:02:12'
      type: 'add'
      character: 456
    },
    {
      timestamp: '2015-07-09 20:02:12'
      type: 'add'
      character: 456
    },
    {
      timestamp: '2015-07-09 20:02:12'
      type: 'add'
      character: 123
    },
    {
      timestamp: '2015-07-09 20:02:12'
      type: 'start'
    }
  ]

wowhead_tooltips = 
  colorlinks: true
  iconizelinks: true
  renamelinks: true
  hide: 
     droppedby: true
     dropchance: true 

Placeholder = React.createClass
  render: ->
    <div className="ui middle aligned divided list">
      <div className="item">
        <div className="right floated content">
          <div className="metadata">2 days ago</div>
        </div>
        <i className="large bitcoin middle aligned icon"></i>
        <div className="content">
          Lena
        </div>
      </div>
      <div className="item">
        <div className="right floated content">
          <div className="metadata">2 days ago</div>
        </div>
        <i className="large bitcoin middle aligned icon"></i>
        <div className="content">
          Lindsay
        </div>
      </div>
      <div className="item">
        <div className="right floated content">
          <div className="metadata">2 days ago</div>
        </div>
        <i className="large bitcoin middle aligned icon"></i>
        <div className="content">
          Mark
        </div>
      </div>
      <div className="item">
        <div className="right floated content">
          <div className="metadata">2 days ago</div>
        </div>
        <i className="large bitcoin middle aligned icon"></i>
        <div className="content">
          Molly
        </div>
      </div>
    </div>