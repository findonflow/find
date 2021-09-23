// File: ./src/App.js

import React, { useState, useEffect } from "react";
import {AuthCluster} from "./auth-cluster"
import {Profile} from "./Profile"
import { Register } from "./Register"
import { Search } from "./Search"
import * as fcl from "@onflow/fcl"

export default function App() {
  const [user, setUser] = useState({loggedIn: null})
  useEffect(() => fcl.currentUser().subscribe(setUser), [])
  
  return (
    <div>
      <AuthCluster user={user}/>
			<div>box left</div>
		  <div>box middle</div>
		  <div>box right</div>
			<Search />
      { user.loggedIn && (
        <div>
					<Register />
				  <hr></hr>
          <Profile user={user} />
				</div>
      )}
    </div>
  )
}
