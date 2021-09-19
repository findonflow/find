import React, { useState, useEffect } from "react";
import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types";

import { scripts } from 'find-flow-contracts'

export function Profile({ user }) {
  const [profile, setProfile] = useState(null);
  useEffect(() => {
    async function getProfile(addr) {
        const response = await fcl.send([
            fcl.script(scripts.profile),
            fcl.args([fcl.arg(addr, t.Address)]),
        ]);
        const profile= await fcl.decode(response);
			  console.log(profile)
        setProfile(profile)
    }
    getProfile(user.addr)
  }, [user]);

  if(!profile)  {
      return <div>create profile like on versus</div>
  }

	return <div> Show the profile { JSON.stringify(profile, null, 2) }</div>
}
