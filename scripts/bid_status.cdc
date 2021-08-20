import FiNS from "../contracts/FiNS.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FiNS.BidInfo]{

	let bidCollection = getAccount(user).getCapability<&{FiNS.BidCollectionPublic}>(FiNS.BidPublicPath)
	return bidCollection.borrow()!.getBids()
}
