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
      <CharacterList characters={@charactersFromGlobal()} clickable=true />
      <button className="ui button">Start a new Raid</button>
    </div>

CharacterList = React.createClass
  getDefaultProps: ->
    clickable: false
  renderCharacters: (character_list) -> 
    <ListCharacter character_id={character.id} clickable={@props.clickable} /> for character in character_list 
  render: ->
    <div className="ui divided selection list">
      {@renderCharacters @props.characters}
    </div>

ListCharacter = React.createClass
  getInitialState: ->
    active: false,
  handleClick: (event) ->
    @setState active:!@state.active if @props.clickable
  render: -> 
    character_info = characters[@props.character_id]
    classes = ['item', 'class', 'class-'+character_info.class]
    classes.push 'active' if @state.active
    <div className={classes.join ' '} onClick={@handleClick}>
      <div className="image">
        <img className="ui avatar image" src={"/images/class_"+character_info.class+".jpg"} />
      </div>
      <div className="content">
        <span>{character_info.name}</span>
      </div>
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

RaidDashboard = React.createClass
  charactersFromGlobal: ->
    Object.keys(characters).map (v) -> id: characters[v].id
  getInitialState: ->
    active_characters: [],
    boss_id: false
  bossSelected: (boss_id) ->
    $('#bossModal').modal 'show'
    @setState boss_id: boss_id 
  render: ->
    <div className="column">
      <BossItemSelection boss_id={@state.boss_id} />
      <div className="ui segment">
        <div className="ui two column middle aligned very relaxed stackable grid">
          <div className="column" style={verticalAlign:"top"}> 
            <CharacterList characters={@charactersFromGlobal()} />
          </div>
          <div className="ui vertical divider">
          </div>
          <div className="center aligned column">
             <RaidMenu bossSelected={@bossSelected} />
          </div>
        </div>    
      </div>
    </div>

RaidMenu = React.createClass
  render: ->
    <div>
      <RaidBossList bossSelected={@props.bossSelected} />
    </div>

 RaidBossCard = React.createClass
  handleClick: ->
    @props.bossSelected(@props.id)
  render: ->
    <div className="item" >
      <div className="right floated content">
        <div className="ui button" onClick={@handleClick}>Downed</div>
      </div> 
      <img className="floated left ui tiny image" src={@props.avatar_url} />
      <div className="content">
        {@props.name}
      </div>
    </div>

RaidBossList = React.createClass
  renderBosses: ->
    ordered_bosses = []
    ordered_bosses.push boss_data for boss_id, boss_data of raid_data
    ordered_bosses.sort (a,b) ->
      a.position - b.position
    <RaidBossCard id={boss_data.id} name={boss_data.name} avatar_url={boss_data.avatar_url} bossSelected={@props.bossSelected} /> for boss_data in ordered_bosses
  render: ->
    <div className="ui big divided list">
      {@renderBosses()}
    </div>   
 

BossLootItem = React.createClass
  incCount: ->
    @props.updateLootList(@props.item.item_id, true)
  decCount: ->  
    @props.updateLootList(@props.item.item_id, false)
  render: ->
    <div className="ui card">
      <div className="content">
        <div className="header">
          <a href="#" rel={"item-"+@props.item.item_id} />
        </div>
      </div>
      <div className="extra content">
        <div className="ui two buttons">
          <div className="ui basic red button" onClick={@decCount}><i className="minus icon"></i></div>
          <div className="ui basic green button" onClick={@incCount}><i className="plus icon"></i></div>
        </div>
      </div>
    </div>

BossLootListItem = React.createClass
  render: ->
    <div className="item">
      <div className="content">
        <div className="header">{@props.count + "x "}</div>
      </div>
      <a href="#" rel={"item-"+@props.item_id} />
    </div>  


BossLootList = React.createClass
  renderListItems: ->
    <BossLootListItem count={item.count} item_id={item.item_id} /> for item in @props.loot_list
  render: ->
    <div className="ui horizontal list">
      {@renderListItems()}      
    </div>
 

BossItemSelection = React.createClass
  getInitialState: ->
    loot_list: []
  resetLootList: ->
    @setState loot_list:[]
  updateLootList: (item_id, inc) ->
    list = @state.loot_list
    new_item = true
    list = list.reduce (p,c) ->
      if c.item_id == item_id
        new_item = false
        c.count += if inc then 1 else -1
        p.push c if c.count > 0
      else
        p.push c
      p
    , []
    list.push (item_id: item_id, count:1) if new_item and inc
    @setState loot_list: list
    console.log list
  componentDidUpdate: ->
    $WowheadPower.refreshLinks() if typeof $WH.isset is "function"
  renderItems: ->
    <BossLootItem item={item} updateLootList={@updateLootList} /> for item in raid_data[@props.boss_id].items if @props.boss_id != false
  render: ->
    boss_data = name: 'None', 'avatar_url': '#'
    boss_data = raid_data[@props.boss_id] if @props.boss_id != false
    <div className="ui fullscreen modal" id="bossModal">
      <i className="close icon"></i>
      <div className="header">
        <div className="ui medium image">
          <img src={boss_data.avatar_url} />
        </div>
        {boss_data.name}
      </div>
      <div className="image content">
        <div className="description">
          <div className="ui header">Select what dropped</div>
          <div className="ui doubling cards">
            {@renderItems()}
          </div>   
        </div>
      </div>
      <h4 className="ui horizontal divider header">
        Final Loot
      </h4>
      <div className="content">
        <BossLootList loot_list={@state.loot_list} />
      </div>
      <div className="actions">
        <div className="ui black deny button">
          Nope
        </div>
        <div className="ui positive right labeled icon button">
          Yep, that's what dropped
          <i className="checkmark icon"></i>
        </div>
      </div>
    </div>

 

#'
# 1. (page) new raid (add ppl) = RaidEmpty
# 2. (page) list + menu (boss, add/remove, end) = RaidDashboard (*List + RaidMenu)
# 3. (menu selection) boss = RaidBossList
# 3a. (modal) select loot  -> confirm = BossItemSelection
# 3b. (page) assign loot -> confirm (for each) = LootAssignment
# 4. (in-page) add/remove (btn activates toggle on list) = (*List now toggles, btn again to commit)
# 5. (modal) end "sure?" -> new raid = goto (1)

LootItem = React.createClass
  render: ->
    <div className="active title">
      <i className="dropdown icon"></i>
      <a href="#" rel={"item-"+@props.data.item_id} />
    </div>
    <div className="active content">
      <p>Selected Person Goes Here</p>
    </div>

LootAssignment = React.createClass
  renderLootItems: -> 
    <LootItem item_id={data.item_id} list_id={data.list_id} /> for data in @props.items
  render: ->
    <div className="ui styled accordion">
      {@renderLootItems}
    </div>


Home = React.createClass
  render: ->
    <div className="column">
      <div className="ui segment">
        <h1 className="ui header">
          <RaidDashboard/>
        </h1>
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
 
