window.$ = window.jQuery = require('jquery')
require('semantic-ui-css/semantic')
React = require('react/addons')
Router = require('react-router')
Header = require('./header')

{Route, RouteHandler, DefaultRoute, Link, Redirect} = Router

RaidEmpty = React.createClass
  charactersFromGlobal: ->
    Object.keys(characters).map (v) -> id: characters[v].id
  render: ->
    <div>
      <CharacterList characters={@charactersFromGlobal()} />
      <button className="ui button">Start a new Raid</button>
    </div>

CharacterList = React.createClass
  renderCharacters: (character_list) -> 
    <ListCharacter character_id={character.id} /> for character in character_list 
  render: ->
    <div className="ui divided selection list">
      {@renderCharacters @props.characters}
    </div>

Login = React.createClass
  render: ->
    <div className="ui modal login">
      <i className="close icon"></i>
      <div className="image content">
        <div className="ui medium image">
          <img src="/images/avatar/large/chris.jpg">
        </div>
        <div className="description">
          <div className="ui header">We've auto-chosen a profile image for you.</div>
          <p>We've grabbed the following image from the <a href="https://www.gravatar.com" target="_blank">gravatar</a> image associated with your registered e-mail address.</p>
          <p>Is it okay to use this photo?</p>
        </div>
      </div>
      <div className="actions">
        <div className="ui black deny button">
          Nope
        </div>
        <div className="ui positive right labeled icon button">
          Yep, thats me
          <i className="checkmark icon"></i>
        </div>
      </div>
    </div>


Home = React.createClass
  render: ->
    <div className="column">
      <div className="ui segment">
        <h1 className="ui header">
          <RaidEmpty/>
        </h1>
      </div>
    </div>

ListCharacter = React.createClass
  render: -> 
    character_info = characters[@props.character_id]
    <div className="item">
      <div className="image">
        <img className="ui avatar image" src={"/images/class_"+character_info.class+".jpg"} />
      </div>
      <div className="content">
        <span>{character_info.name}</span>
      </div>
    </div>

LogItemLoot = React.createClass
  render: -> 
    <span>{characters[@props.data.subject_id].name} looted <a href="#" rel={"item-"+@props.data.object_id} /></span>

LogItemRaidAdd = React.createClass
  render: -> 
    <span>{characters[@props.data.subject_id].name} joined raid</span>

LogItemRaidRem = React.createClass
  render: -> 
    <span>{characters[@props.data.subject_id].name} left raid</span>

LogItemRaidStart = React.createClass
  render: -> 
    <span>Raid Started :D</span>

LogItemRaidEnd = React.createClass
  render: -> 
    <span>Raid Ended :(</span>

LogItemBoss = React.createClass
  render: -> 
    <span><a href="#" rel={"npc-"+@props.data.subject_id} /> killed!</span>

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
        icon: 'crosshairs'
      loot: 
        el: LogItemLoot
        icon: 'bitcoin'
    Item = LogItems[@props.data.action]
    <div className="item">
      <div className="right floated content">
        <div className="metadata">{moment(@props.data.timestamp, "YYYY-MM-DD HH:mm:ss").fromNow()}</div>
      </div>
      <i className={"large middle aligned icon "+Item.icon}></i>
      <div className="content raid-log">
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
  contextTypes: 
    router: React.PropTypes.func.isRequired
  getInitialState: ->
    characters: characters
  componentDidMount: -> 
    # This is to tell the wowhead widget to re-linkify everything, otherwise it breaks whenever a component re-mounts
    $WowheadPower.refreshLinks() if typeof $WH.isset is "function"
  renderCharacters: (list_id) -> 
    list = lists[list_id]
    <ListCharacter character_id={character.character_id} /> for n, character of list 
  charactersFromList: ->
    list = lists[@props.params.list_id]
    Object.keys(list).map (v) -> id: list[v].character_id
  render: -> 
    <div className="column">
      <div className="ui segment">
        <div className="ui two column middle aligned very relaxed stackable grid">
          <div className="column" style={verticalAlign:"top"}> 
            <div className="ui two top attached buttons">
                <div className="ui button active" onClick={(() -> this.context.router.transitionTo('/list/1')).bind(this)}>Armor</div>
                <div className="ui button" onClick={(() -> this.context.router.transitionTo('/list/2')).bind(this)}>Tier</div>
                <div className="ui button" onClick={(() -> this.context.router.transitionTo('/list/3')).bind(this)}>Weapons/Trinkets</div>
                <div className="ui button" onClick={(() -> this.context.router.transitionTo('/list/4')).bind(this)}>Accessories</div>
            </div>
            <CharacterList characters={@charactersFromList()} />
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
  getInitialState: ->
      character_data: characters
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
    <Route name="list" path="/list/:list_id" handler={List}/>
    <Redirect from="list" to="list" params={{list_id:1}} />
  </Route>

$ ->
  Router.run routes, Router.HashLocation, (Handler, state) ->
    React.render(<Handler params=state.params />, document.body)
 
wowhead_tooltips = 
  colorlinks: true
  iconizelinks: true
  renamelinks: true
  hide: 
     droppedby: true
     dropchance: true 
 
