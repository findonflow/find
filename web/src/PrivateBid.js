import TimeAgo from 'react-timeago'
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";
import EasyEdit from 'react-easy-edit';

import { tx } from "./transaction";
import { transactions } from 'find-flow-contracts'



export function PrivateBid({ bid }) {
	const handleIncreaseBid = async (value) => {
		try {
      await tx(
        [
          fcl.transaction(transactions.increaseBid),
          fcl.args([
            fcl.arg(bid.name, t.String),
						fcl.arg(value, t.UFix64)
          ]),
          fcl.proposer(fcl.currentUser().authorization),
          fcl.payer(fcl.currentUser().authorization),
          fcl.authorizations([fcl.currentUser().authorization]),
          fcl.limit(9999),
        ],
        {
          onStart() {
						console.log("start")
          },
          onSubmission() {
						console.log("submitted")
          },
          async onSuccess(status) {
						console.log("success")
            const event = document.createEvent("Event");
            event.initEvent("bid", true, true);
            document.dispatchEvent(event);
          },
          async onError(error) {
            if (error) {
              const { message } = error;
							console.log(message)
            }
          },
        }
      );
    } catch (e) {
      console.log(e);
    }
	}

  const handleCancelBid = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.cancelBid),
          fcl.args([
            fcl.arg(bid.name, t.String)
          ]),
          fcl.proposer(fcl.currentUser().authorization),
          fcl.payer(fcl.currentUser().authorization),
          fcl.authorizations([fcl.currentUser().authorization]),
          fcl.limit(9999),
        ],
        {
          onStart() {
						console.log("start")
          },
          onSubmission() {
						console.log("submitted")
          },
          async onSuccess(status) {
						console.log("success")
            const event = document.createEvent("Event");
            event.initEvent("bid", true, true);
            document.dispatchEvent(event);
          },
          async onError(error) {
            if (error) {
              const { message } = error;
							console.log(message)
            }
          },
        }
      );
    } catch (e) {
      console.log(e);
    }
  }

	return <div>Bid made for lease {bid.name} for <EasyEdit value={bid.amount} type="number" placeholder="Increase bid" instructions="Increase bid" onSave={handleIncreaseBid} /> FUSD {<TimeAgo date={new Date(bid.timestamp * 1000)} />} <button text="cancelBid" onClick={handleCancelBid}>Cancel</button></div>
		//TODO: Format number down to 2 digits not 8
}
