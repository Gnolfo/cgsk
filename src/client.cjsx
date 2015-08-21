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
  ci: ->
    <CharacterInline character_id={@props.character_id} />
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

CharacterInline = React.createClass
  render: ->
    character_info = window.characters[@props.character_id]
    <div>
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
    loot_items: [],
    raiding_characters: [],
    looting: false,
    list_id: 1
  componentWillMount: ->
    @changeLootList 1
  bossSelected: (boss_id) ->
    $('#bossModal').modal 'show'
    @setState boss_id: boss_id, loot_items: [] 
  updateLootList: (item, inc) ->
    list = @state.loot_items
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
    @setState loot_items: list 
  doneLooting: ->
    @setState loot_items: [], looting: false
  getRightCol: ->
    if @state.loot_items.length > 0 and @state.looting
      <LootAssignment items={@state.loot_items} itemSelected={@itemSelected} itemLooted={@itemLooted} raidingCharacters={@state.raiding_characters} doneLooting={@doneLooting} />
    else
      <RaidMenu bossSelected={@bossSelected} raidEnded={@props.raidEnded} loot_items={@state.loot_items} />
  showList: (list_id) ->
    @changeLootList list_id if !@state.looting
  showListNavButton: (list_id) ->
    classes = ['ui','button']
    classes.push 'active' if @state.list_id == list_id
    <div className={classes.join ' '} onClick={(() -> this.showList(list_id)).bind(this)}>{list_map[list_id]}</div>
  showListNavButtons: ->
    lists = [1,2,3,4]
    @showListNavButton(list_id) for list_id in lists
  showListNav: ->
    list_name = list_map[@state.list_id]
    if @state.looting
      {list_name}
    else
      <div className="ui two top attached buttons">
        {@showListNavButtons()}
      </div>
  itemSelected: (item) ->
    @changeLootList item.list_id
  changeLootList:  (list_id) ->
    self = this
    list = window.lists[list_id]
    raiding_characters = Object.keys(list).filter (v) -> 
      id = list[v].character_id
      self.props.character_list.reduce (p,c) ->
        p = true if c.id == id 
        p
      , false
    raiding_characters = raiding_characters.map (v) -> id: list[v].character_id, active: false
    @setState raiding_characters: raiding_characters, list_id: list_id
  characterToggled: (character_id, activated) ->
    if @state.looting
      new_list = @state.raiding_characters.map (v) ->
        v.active = activated if v.id == character_id
        v
      @setState raiding_characters: new_list
  commitLoot: ->
    @setState looting: true
  finishedLooting: ->
    @setState looting: false
  render: ->
    <div className="column">
      <BossItemSelection boss_id={@state.boss_id} loot_items={@state.loot_items} updateLootList={@updateLootList} commitLoot={@commitLoot} />
      <div className="ui segment">
        <div className="ui two column middle aligned very relaxed stackable grid">
          <div className="column" style={verticalAlign:"top"}> 
            {@showListNav()}
            <CharacterList characters={@state.raiding_characters} characterToggled={@characterToggled} clickable={@state.looting} />
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
        <RaidBossList bossSelected={@props.bossSelected} loot_items={@props.loot_items} />
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
        <BossLootList loot_list={@props.loot_items} />
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
  getInitialState: ->
    confirmingLoot: false,
    winner: false,
    lootConfirmed: false
  componentWillReceiveProps: (newProps) ->
    winner = @getWinner newProps
    @cancelProposal() if winner != @state.winner and !@state.lootConfirmed
  getWinner: (fakeProps) ->
    if @state.lootConfirmed
        @state.winner
    else 
      props = if fakeProps then fakeProps else @props
      props.raidingCharacters.reduce (p,c) ->
        p = c if c.active and (!p or p.position > c.position)
        p
      , false
  proposeLoot: ->
    if !@state.lootConfirmed
      winner = @getWinner()
      @setState confirmingLoot: true, winner: winner
  cancelProposal: ->
    @setState confirmingLoot: false
  confirmProposal: ->
    self = this
    $.post '/loot', character_id: @state.winner.id, item_id: @props.item.item_id, list_id: @props.item.list_id, raid_id: window.raid_id
    .done (data) ->
      window.lists = data.lists if data.lists?
      self.props.itemSelected self.props.item 
    .fail (data) ->
      alert data.responseJSON.message      
    @setState lootConfirmed: true
  handleClick: ->
    @props.itemSelected @props.item 
  winnerSelection: (winner) ->
    if winner then <CharacterInline character_id={winner.id} /> else <p>Select any players who bid</p>
  lootButton: (winner) ->
    if @state.lootConfirmed
      <span>Looted and Suicided!</span>
    else if !winner or @state.winner != winner or !@state.confirmingLoot 
      <button onClick={@proposeLoot}>Loot!</button> 
    else 
       <div className="ui buttons">
        <button className="ui negative button" onClick={@cancelProposal}>Cancel</button>
        <div className="or"></div>
        <button className="ui positive button" onClick={@confirmProposal}>Confirm</button>
      </div>
  render: ->
    winner = @getWinner()
    <div>
      <div className="title" onClick={@handleClick}>
        <i className="dropdown icon"></i>
        <a href="#" rel={"item-"+@props.item.item_id} />
      </div>
      <div className="content">
        {@winnerSelection(winner)}
        {@lootButton(winner)}
      </div>
    </div>

LootAssignment = React.createClass
  getInitialState: ->
    proposeDone: false
  componentDidMount: ->
    $('.ui.accordion').accordion()
  getDoneButton: ->
    if @state.proposeDone 
      <div className="ui buttons">
        <button className="ui negative button" onClick={@cancelProposal}>Cancel</button>
        <div className="or"></div>
        <button className="ui positive button" onClick={@doneLooting}>Confirm</button>
      </div>
    else
      <button onClick={@proposeDone}>Done Looting</button>
  proposeDone: ->
    @setState proposeDone: true
  cancelProposal: ->
    @setState proposeDone: false
  doneLooting: ->
    @props.doneLooting()
  renderLootItems: -> 
    <LootItem item={data.item} itemSelected={@props.itemSelected} raidingCharacters={@props.raidingCharacters} /> for n in [1..data.count] for data in @props.items
  render: ->
    <div>
      <div className="ui styled accordion">
        {@renderLootItems()}
      </div>
      <div className="ui content">
        {@getDoneButton()}
      </div>
    </div>

Home = React.createClass
  getInitialState: ->
    raid_id: window.raid_id,
    active_raiders: window.active_raiders
  raidEnded: ->
    if confirm 'Are you sure you want to end the raid?' 
      $.post '/end', raid_id: window.raid_id
      .fail (data) ->
        alert data.responseJSON.message      
      window.raid_id = false
      @setState raid_id: false, active_raiders: []    
  raidStarted: (character_list) ->
    self = this
    list = character_list.map (v) -> 
      v.id
    $.post '/start', characters: list
    .done (data) ->
      if data.raid_id?
        window.scrollTo 0, 0
        window.raid_id = data.raid_id 
        self.setState raid_id: window.raid_id, active_raiders: character_list
      else 
        alert data.error if data.error?
    .fail (data) ->
      alert data.responseJSON.message
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
        <div className="metadata">{moment.utc(@props.data.timestamp).fromNow()}</div>
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
        <h4 className="ui black header">Pretend this page has a low quality animated gif of a construction figure.</h4>
      </div>
    </div>

Main = React.createClass
  getInitialState: ->
      character_data: window.characters,
      logged_in: window.logged_in
  loginUpdated: (logged_in) ->
    this.setState logged_in: logged_in unless @state.logged_in == logged_in
  render: ->
    <div>
      <Header logged_in={@state.logged_in} loginUpdated={@loginUpdated}/>
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
 
