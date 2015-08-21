import React from "react/addons"
import Router from "react-router"

let {Link} = Router

export default React.createClass({
  startLoader: function() {
    $('#loginLoader').addClass('active');
  },
  stopLoader: function() {
    $('#loginLoader').removeClass('active');
  },
  doLogin: function() {
    var username = $('#login_username').val()
    var password = $('#login_password').val()
    if( !username || !password) {
      return;
    }
    var self = this 
    self.startLoader()
    $.post('/login', {username: username, password: password})
    .done (function(data) {
      self.stopLoader()
      if( data.success ) {
        self.props.loginUpdated(true)
      } else {
        alert('Invalid login credentials')
      }
    })
  },
  doLogout: function () {
    var self = this
    self.startLoader()
    $.post('/logout')
    .done (function(data) {
      self.stopLoader()
      if( data.success ) {
        self.props.loginUpdated(false)
      } else {
        alert('Unable to log out :(')
      }
    })
  },
  checkEnter: function (e) {
    if (!e) {
      e = window.event;
    }
    var keyCode = e.keyCode || e.which;
    if (keyCode == '13'){
      this.doLogin()
    }
  },
  render: function() {
    var loginButton = <div className="ui mini form">
        <div className="three fields">
          <div className="field">
            <input placeholder="Username" type="text" tabIndex="1" onKeyDown={this.checkEnter} id="login_username" />
          </div>
          <div className="field">
            <input placeholder="Password" type="password" tabIndex="2" onKeyDown={this.checkEnter} id="login_password" />
          </div>
          <div className="ui mini submit button" tabIndex="3" onClick={this.doLogin}  >Log in</div>
          <div className="ui inline loader" id="loginLoader">&nbsp;</div>
        </div>
      </div>
    if (this.props.logged_in)
      loginButton = <div className="ui button" onClick={this.doLogout}>Log out</div>
    var raid_link = ""
    if( this.props.logged_in )
      raid_link = <Link className="item" to="home">
              Raid
            </Link>
    var manage_link = ""
    if( this.props.logged_in )
      manage_link = <Link className="item" to="about">
              Manage
            </Link>
    return <div className="ui pointing menu">
        <div className="ui page grid">
          <div className="column" style={{"padding-bottom": 0}}>
            <div className="title item">
              <b>California Gurls</b>
            </div>
            {raid_link}
        	  <Link className="item" to="list" params={{ list_id:1 }}>
        	    Lists
        	  </Link>
            {manage_link}
            <div className="right floated item">
              {loginButton}
            </div>
          </div>
        </div>
      </div>
  }
});
