// File: ./src/App.js

import React, { useState, useEffect } from "react";
import {AuthCluster} from "./auth-cluster"
import {Profile} from "./Profile"
import { Register } from "./Register"
import { Leases } from "./Leases"
import * as fcl from "@onflow/fcl"

export default function App() {
  const [user, setUser] = useState({loggedIn: null})
  useEffect(() => fcl.currentUser().subscribe(setUser), [])
  
  return (
    <div>
      <AuthCluster user={user}/>
		  <div>FIND a name for your profile on flow. <br/> <input></input> search box like duckduckgo/google</div>
			<div>box left</div>
		  <div>box middle</div>
		  <div>box right</div>
      { user.loggedIn && (
        <div>
				  <hr></hr>
          <Profile user={user} />
				  <Register />
				  <Leases user={user}/>
				  
				</div>
      )}
    </div>
  )
}
