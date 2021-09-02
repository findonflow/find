import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIND.BidInfo]{

	let bidCollection = getAccount(user).getCapability<&{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	return bidCollection.borrow()!.getBids()
}
