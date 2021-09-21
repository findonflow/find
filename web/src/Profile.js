import React, { useState, useEffect } from "react";
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";
import {PrivateLease} from "./PrivateLease";
import {PrivateBid} from "./PrivateBid";
import { scripts } from 'find-flow-contracts';

export function Profile({ user }) {
  const [findUser, setFindUser] = useState(null);
  useEffect(() => {
    async function getFindUser(addr) {
        const response = await fcl.send([
            fcl.script(scripts.address_status),
            fcl.args([fcl.arg(addr, t.Address)]),
        ]);
        const findUser= await fcl.decode(response);
			  console.log(findUser)
				setFindUser(findUser)
    }
    getFindUser(user.addr)
  }, [user]);

  if(!findUser)  { 
		return <div>create profile like on versus</div>
  }


	return <div>

		<div> Show the profile { JSON.stringify(findUser.profile, null, 2) }</div>
		<h2>Leases</h2>
		Probably want a table here or something. 
		{ findUser.leases.map ((lease) => <PrivateLease lease={lease} />)}
		<h2>Bids</h2>
		{ findUser.bids.map ((bid) => <PrivateBid bid={bid} />)}
		<div> Show the bids { JSON.stringify(findUser.bids, null, 2)}</div>

		</div>
}
