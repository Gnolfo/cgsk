import React from "react/addons"
import Router from "react-router"

let {Link} = Router

export default React.createClass({
  render: function() {
    return <div className="ui pointing menu">
      <div className="ui page grid">
        <div className="column" style={{"padding-bottom": 0}}>
          <div className="title item">
            <b>California Gurls</b>
          </div>
          <Link className="item" to="home">
            Raid
          </Link>
      	  <Link className="item" to="list" params={{ list_id:1 }}>
      	    Lists
      	  </Link>
          <Link className="item" to="about">
            Manage
          </Link>
          <div className="right floated item">
            <div className="ui button">Log in</div>
          </div>
        </div>
      </div>
    </div>
  }
});
