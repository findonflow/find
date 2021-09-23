import TimeAgo from 'react-timeago'
import * as fcl from "@onflow/fcl";
import * as t from "@onflow/types";
import EasyEdit from 'react-easy-edit';

import { tx } from "./transaction";
import { transactions } from 'find-flow-contracts'

export function PrivateLease({ lease }) {
	//all of these transactions can be done a lot smoother
  const handleActivate = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.register),
          fcl.args([
            fcl.arg(lease.name, t.String)
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

  const handleSell = async (value) => {

		//format value properly
		try {
      await tx(
        [
          fcl.transaction(transactions.sell),
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

const handleFullfillSale = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.fullfill),
          fcl.args([
            fcl.arg(lease.name, t.String)
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

  const handleStartAuction = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.startAuction),
          fcl.args([
            fcl.arg(lease.name, t.String)
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
  const handleCancel = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.cancelAuction),
          fcl.args([
            fcl.arg(lease.name, t.String)
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


  const handleFullfillAuction = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.fullfill_auction),
          fcl.args([
						fcl.arg(fcl.currentUser().address, t.Address),
            fcl.arg(lease.name, t.String)
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

  const handleExtend = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.renew),
          fcl.args([
            fcl.arg(lease.name, t.String)
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
  const handleProfile = async (e) => {
    e.preventDefault();
    try {
      await tx(
        [
          fcl.transaction(transactions.edit_profile),
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
	 
	let durationLegend= <div>GREEN:valid until {<TimeAgo date={new Date(lease.expireTime * 1000)} />} <button text="extend" onClick={handleExtend}>Extend</button></div>
	if(lease.status.rawValue.value === 2) {
		durationLegend= <div>RED:locked until {<TimeAgo date={new Date(lease.expireTime * 1000)} />} <button text="renew" onClick={handleActivate}>Activate</button></div>
	}

	let bids= null
	if(lease.auctionEnds != null) {
		let button =null
		if(lease.auctionEnds <= lease.currentTime) {
			button= <button text="fullfill" onClick={ handleFullfillAuction}>Fullfill</button>
		} else {
			button= <button text="cancel" onClick={ handleCancel} >Cancel</button>
		}

		bids= <div>Ongoing auction until { <TimeAgo date={new Date(lease.auctionEnds * 1000)} />  } latest bid { lease.latestBid } FUSD  { button}</div>
	} else if (lease.latestBid != null) {
		bids= <div>Blind bid from { lease.latestBidBy} at {lease.latestBid } FUSD <button text="reject" onClick={handleCancel} >Reject</button> <button text="sell" onClick={handleFullfillSale}>Sell</button> <button text="auction" onClick={handleStartAuction}>Start auction</button> </div>
	}

	let sale=null
	if(bids === null) {
		let listFor= <span>selling for:</span>
		if(lease.salePrice===null) {
			listFor= <span>list for sale:</span>
		}

		sale= <div> {listFor} <EasyEdit value={lease.salePrice} type="number" placeholder="Sell!" instructions="List for sale" onSave={handleSell} saveButtonLabel="Sell" /> </div>
			//need to show better text when it is for sale and not for sale here
	} 	

	return <div>
		name: { lease.name} {durationLegend}  { bids} { sale } <br /> 
		<button onClick={handleProfile}>Add fusd to profile</button>
		</div>
		//{JSON.stringify(lease, null, 2)}
}
