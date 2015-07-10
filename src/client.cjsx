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
      </div>
    </div>

List = React.createClass
  getInitialState: ->
    characters: characters
  renderCharacters: -> 
    <ListCharacter character_id={character_id} /> for character_id in @state.characters 
  render: -> 
    <div className="column">
      <div className="ui segment">
        <div className="ui divided selection list">
          {@renderCharacters()}
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


