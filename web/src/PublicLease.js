import TimeAgo from 'react-timeago'
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";
import EasyEdit from 'react-easy-edit';

import { tx } from "./transaction";
import { transactions } from 'find-flow-contracts'

export function PublicLease({ lease }) {
  const handleBid = async (value) => {

		//format value properly
		try {
      await tx(
        [
          fcl.transaction(transactions.bid),
          fcl.args([
            fcl.arg(lease.name, t.String),
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

	 
	let durationLegend= <div>GREEN:valid until {<TimeAgo date={new Date(lease.expireTime * 1000)} />}</div> 
	if(lease.status.rawValue.value === 2) {
		durationLegend= <div>RED:locked until {<TimeAgo date={new Date(lease.expireTime * 1000)} />}</div>
	}

	let bidLegend="Blind Bid"
	if(lease.auctionEnds !== null && lease.salePrice !== null) {
		bidLegend="Add auction bid"
	} else if( lease.salePrice !== null) {
		bidLegend="Bid"
	} 
	return <div>
		name: { lease.name} {durationLegend}  <br /> 
		<div> {bidLegend}: <EasyEdit value={lease.latestBid || 5.0} type="number" placeholder="Blind Bid!" instructions="Put in a blind bid for this name" onSave={handleBid} saveButtonLabel="Bid" /> </div>
		{JSON.stringify(lease, null, 2)}
		</div>
}
