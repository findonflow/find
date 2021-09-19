import React, { useState, useEffect } from "react";
import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types";

import { scripts } from 'find-flow-contracts'

export function Leases({ user }) {
  const [leases, setLeases] = useState(null);
  useEffect(() => {
    async function getLeases(addr) {
        const response = await fcl.send([
            fcl.script(scripts.lease_status),
            fcl.args([fcl.arg(addr, t.Address)]),
        ]);
        const leases= await fcl.decode(response);
			  console.log(leases)
        setLeases(leases)
    }
    getLeases(user.addr)
  }, [user]);


	return <div> Show the leases { JSON.stringify(leases, null, 2) }</div>
}
