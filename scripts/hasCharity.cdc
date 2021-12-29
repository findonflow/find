import CharityNFT from "../contracts/CharityNFT.cdc"

//Check the status of a fin user
pub fun main(user: Address) : Bool {
	let account=getAccount(user)
	let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	return charityCap.check()
}
