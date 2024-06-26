import FIND from "../contracts/FIND.cdc"

pub fun main(address: [Address]) : { Address:String}{

	let items : {Address:String} = {}
	for a in address {
		if let name= FIND.reverseLookup(a) {
			items[a]=name
		}
	}
	return items
}
