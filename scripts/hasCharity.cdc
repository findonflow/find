import CharityNFT from "../contracts/CharityNFT.cdc"

pub fun main(user: Address) : Bool {
	let account=getAccount(user)
	if account.balance == 0.0 {
		return false
	}
	let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
	return charityCap.check()
}
