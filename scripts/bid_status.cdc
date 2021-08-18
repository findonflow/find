import FIN from "../contracts/FIN.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIN.BidInfo]{

	let bidCollection = getAccount(user).getCapability<&{FIN.BidCollectionPublic}>(FIN.BidPublicPath)
	return bidCollection.borrow()!.getBids()
}
