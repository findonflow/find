import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIND.BidInfo]{

	let bidCap = getAccount(user).getCapability<&{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	if let bidCollection = bidCap.borrow() {
		return bidCollection.getBids()
	}
	return []
}
