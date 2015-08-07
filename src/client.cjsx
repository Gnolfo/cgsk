window.$ = window.jQuery = require('jquery')
require('semantic-ui-css/semantic')
React = require('react/addons')
Router = require('react-router')
Header = require('./header')

{Route, RouteHandler, DefaultRoute, Link, Redirect} = Router

RaidEmpty = React.createClass
  getInitialState: ->
    clist = Object.keys(window.characters).map (v) -> 
      id: window.characters[v].id, active: false
    character_list: clist
  startRaid: ->
    @props.raidStarted (@state.character_list.filter (v) -> v.active) if confirm 'Are you sure you want to start a new raid?'
  characterToggled: (character_id, active) ->
    character_list = @state.character_list.map (v) ->
      v.active = active if v.id == character_id
      v
    @setState character_list: character_list
  render: ->
    <div>
      <CharacterList id="raid-roster" characters={@state.character_list} clickable=true characterToggled={@characterToggled}/>
      <button className="ui button" onClick={@startRaid}>Start a new Raid</button>
    </div>

CharacterList = React.createClass
  getDefaultProps: ->
    clickable: false
  renderCharacters: (character_list) -> 
    <ListCharacter character_id={character.id} clickable={@props.clickable}
      characterToggled={@props.characterToggled} active={character.active} /> for character in character_list 
  render: ->
    <div className="ui divided selection list">
      {@renderCharacters @props.characters}
    </div>

ListCharacter = React.createClass
  handleClick: (event) ->
    @props.characterToggled @props.character_id, !@props.active 
  render: -> 
    character_info = window.characters[@props.character_id]
    classes = ['item', 'class', 'class-'+character_info.class]
    classes.push 'active' if @props.active
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
  getInitialState: ->
    boss_id: false,
    loot_list: [],
    looting: false,
    list_id: 1,
  bossSelected: (boss_id) ->
    $('#bossModal').modal 'show'
    @setState boss_id: boss_id, loot_list: [] 
  updateLootList: (item, inc) ->
    list = @state.loot_list
    new_item = true
    list = list.reduce (p,c) ->
      if c.item.item_id == item.item_id
        new_item = false
        c.count += if inc then 1 else -1
        p.push c if c.count > 0
      else
        p.push c
      p
    , []
    list.push (item: item, count:1) if new_item and inc
    @setState loot_list: list 
  getRightCol: ->
    if @state.loot_list.length > 0 and @state.looting
      <LootAssignment items={@state.loot_list} itemSelected={@itemSelected} itemLooted={@itemLooted} />
    else
      <RaidMenu bossSelected={@bossSelected} raidEnded={@props.raidEnded} loot_list={@state.loot_list} />
  itemSelected: (item) ->
    @setState list_id: item.list_id
  activeCharactersFromList: ->
    self = this
    list = window.lists[@state.list_id]
    active_list = Object.keys(list).filter (v) -> 
      id = list[v].character_id
      self.props.character_list.reduce (p,c) ->
        p = true if c.id == id 
        p
      , false
    active_list = active_list.map (v) -> id: list[v].character_id, active: false
    active_list
  characterToggled: (character_id, active) ->
    if looting
      5
  commitLoot: ->
    @setState looting: true
  finishedLooting: ->
    @setState looting: false
  render: ->
    active_list = @activeCharactersFromList()
    <div className="column">
      <BossItemSelection boss_id={@state.boss_id} loot_list={@state.loot_list} updateLootList={@updateLootList} commitLoot={@commitLoot} />
      <div className="ui segment">
        <div className="ui two column middle aligned very relaxed stackable grid">
          <div className="column" style={verticalAlign:"top"}> 
            {list_map[@state.list_id]}
            <CharacterList characters={active_list} characterToggled={@characterToggled} clickable={@state.looting} />
          </div>
          <div className="ui vertical divider">
          </div>
          <div className="center aligned column">
             {@getRightCol()}
          </div>
        </div>    
      </div>
    </div>

RaidMenu = React.createClass
  componentDidMount: ->
    $('.ui.accordion').accordion()
  render: ->
    <div className="ui styled accordion">
      <div className="title">
        <i className="dropdown icon"></i>
        Boss Selection
      </div>
      <div className="content">
        <RaidBossList bossSelected={@props.bossSelected} loot_list={@props.loot_list} />
      </div>
      <div className="title">
        <i className="dropdown icon"></i>
        Add/Remove
      </div>
      <div className="content">
        Coming soon!
      </div>
      <div className="title">
        <i className="dropdown icon"></i>
        Finish Raid
      </div>
      <div className="content">
        <RaidEnd raidEnded={@props.raidEnded}/>
      </div>
    </div>

RaidEnd = React.createClass
  handleClick: ->
    @props.raidEnded()
  render: ->
    <div className="content">
      <button className="ui button" onClick={@handleClick}>End Raid</button>
    </div>

RaidBossCard = React.createClass
  handleClick: ->
    @props.bossSelected(@props.id)
  render: ->
    <div className="item" >
      <div className="right floated content">
        <div className="ui button" onClick={@handleClick}>Downed</div>
      </div> 
      <img className="left floated ui tiny image" src={@props.avatar_url} />
      <div className="content">
        {@props.name}
      </div>
    </div>

RaidBossList = React.createClass
  renderBosses: ->
    ordered_bosses = []
    ordered_bosses.push boss_data for boss_id, boss_data of window.raid_data
    ordered_bosses.sort (a,b) ->
      a.position - b.position
    <RaidBossCard id={boss_data.id} name={boss_data.name} avatar_url={boss_data.avatar_url} bossSelected={@props.bossSelected} /> for boss_data in ordered_bosses
  render: ->
    <div className="ui big divided list">
      {@renderBosses()}
    </div>   
 

BossLootItem = React.createClass
  incCount: ->
    @props.updateLootList(@props.item, true)
  decCount: ->  
    @props.updateLootList(@props.item, false)
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
      <a href="#" rel={"item-"+@props.item.item_id} />
    </div>  


BossLootList = React.createClass
  renderListItems: ->
    <BossLootListItem count={item_data.count} item={item_data.item} /> for item_data in @props.loot_list
  render: ->
    <div className="ui horizontal list">
      {@renderListItems()}      
    </div>
 

BossItemSelection = React.createClass
  componentDidUpdate: ->
    $WowheadPower.refreshLinks() if typeof $WH.isset is "function"
  renderItems: ->
    <BossLootItem item={item} updateLootList={@props.updateLootList} /> for item in window.raid_data[@props.boss_id].items if @props.boss_id != false
  render: ->
    boss_data = name: 'None', 'avatar_url': '#'
    boss_data = window.raid_data[@props.boss_id] if @props.boss_id != false
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
        <BossLootList loot_list={@props.loot_list} />
      </div>
      <div className="actions">
        <div className="ui black deny button">
          Nope
        </div>
        <div className="ui positive right labeled icon button" onClick={@props.commitLoot}>
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
  handleClick: ->
    @props.itemSelected @props.item 
  render: ->
    <div>
      <div className="title" onClick={@handleClick}>
        <i className="dropdown icon"></i>
        <a href="#" rel={"item-"+@props.item.item_id} />
      </div>
      <div className="content">
        <p>Selected Person Goes Here</p>
      </div>
    </div>

LootAssignment = React.createClass
  componentDidMount: ->
    $('.ui.accordion').accordion()
  renderLootItems: -> 
    <LootItem item={data.item} itemSelected={@props.itemSelected} /> for n in [1..data.count] for data in @props.items
  render: ->
    <div className="ui styled accordion">
      {@renderLootItems()}
    </div>

Home = React.createClass
  getInitialState: ->
    raid_id: window.raid_id,
    active_raiders: window.active_raiders
  raidEnded: ->
    if confirm 'Are you sure you want to end the raid?' 
      $.post '/end', raid_id: window.raid_id
      window.raid_id = false
      @setState raid_id: false, active_raiders: []    
  raidStarted: (character_list) ->
    self = this
    list = character_list.map (v) -> 
      v.id
    $.post '/start', characters: list
    .done (data) ->
      if data.raid_id?
        window.raid_id = data.raid_id 
        self.setState raid_id: window.raid_id, active_raiders: character_list
      else 
        alert data.error if data.error?
  getRaidPanel: ->
    if window.raid_id isnt false then <RaidDashboard raid_id={window.raid_id} character_list={@state.active_raiders} raidEnded={@raidEnded} /> else <RaidEmpty raidStarted={@raidStarted}/>
  render: ->
    <div className="column">
      <div className="ui segment">
        <h1 className="ui header">
          {@getRaidPanel()}
        </h1>
      </div>
    </div>

LogItemLoot = React.createClass
  render: -> 
    <span>{window.characters[@props.data.subject_id].name} looted <a href="#" rel={"item-"+@props.data.object_id} /></span>

LogItemRaidAdd = React.createClass
  render: -> 
    <span>{window.characters[@props.data.subject_id].name} joined raid</span>

LogItemRaidRem = React.createClass
  render: -> 
    <span>{window.characters[@props.data.subject_id].name} left raid</span>

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
    logs: window.logs
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
    characters: window.characters
  componentDidMount: -> 
    # This is to tell the wowhead widget to re-linkify everything, otherwise it breaks whenever a component re-mounts
    $WowheadPower.refreshLinks() if typeof $WH.isset is "function"
  renderCharacters: (list_id) -> 
    list = window.lists[list_id]
    <ListCharacter character_id={character.character_id} /> for n, character of list 
  charactersFromList: ->
    list = window.lists[@props.params.list_id]
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
      character_data: window.characters
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
 
list_map = {
  1: 'Armor',
  2: 'Tier',
  3: 'Weapons/Trinkets',
  4: 'Accessories'
}

wowhead_tooltips = 
  colorlinks: true
  iconizelinks: true
  renamelinks: true
  hide: 
     droppedby: true
     dropchance: true 
 
