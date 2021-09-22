import TimeAgo from 'react-timeago'


export function PrivateLease({ lease }) {

	 
	let durationLegend= <div>GREEN:valid until {<TimeAgo date={new Date(lease.expireTime * 1000)} />} <button text="extend">Extend</button></div>
	if(lease.status.rawValue.value === 2) {
		durationLegend= <div>RED:locked until {<TimeAgo date={new Date(lease.expireTime * 1000)} />} <button text="renew">Renew</button></div>
	}

	let bids= null
	if(lease.auctionEnds != null) {
		let button =null
		if(lease.auctionEnds <= lease.currentTime) {
			button= <button text="fullfill">Fullfill</button>
		} else {
			button= <button text="cancel">Cancel</button>
		}

		bids= <div>Ongoing auction until { <TimeAgo date={new Date(lease.auctionEnds * 1000)} />  } latest bid { lease.latestBid } FUSD  { button}</div>
	} else if (lease.latestBid != null) {
		bids= <div>Blind bid from { lease.latestBidBy} at {lease.latestBid } FUSD <button text="reject">Reject</button> <button text="sell">Sell</button> <button text="auction">Start auction</button> </div>
	}

	let sale=null
	if(bids === null) {
		if(lease.salePrice != null) {
			sale= <div>listed for: { lease.salePrice} FUSD. Change price button</div>
		} else {
			sale= <button text="sell">Sell</button>
		}
	}

	return <div>
		name: { lease.name} {durationLegend}  { bids} { sale } <br /> 
		{JSON.stringify(lease, null, 2)}
		</div>
}
