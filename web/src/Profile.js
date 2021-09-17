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
        setProfile(profile)
    }
    getProfile(user.addr)
  }, [user]);

  console.log(profile)
  if(!profile)  {
      return <div> No Profile</div>
  }
  return <div> {profile}</div>
}
