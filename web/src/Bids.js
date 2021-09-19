import React, { useState, useEffect } from "react";
import * as fcl from "@onflow/fcl"
import * as t from "@onflow/types";

import { scripts } from 'find-flow-contracts'

export function Bids({ user }) {
  const [bids, setBids] = useState(null);
  useEffect(() => {
    async function getBids(addr) {
        const response = await fcl.send([
            fcl.script(scripts.bid_status),
            fcl.args([fcl.arg(addr, t.Address)]),
        ]);
        const bids= await fcl.decode(response);
			  console.log(bids)
        setBids(bids)
    }
    getBids(user.addr)
  }, [user]);

  return <div> Show the bids { JSON.stringify(bids, null, 2) }</div>

		/*
		* Transactions:  increaseBid: to increase the bid
		* TODO: fix bid scripts so that it can return empty
		*/
}
