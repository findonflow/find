import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

pub fun main(address: Address) : [UInt64] {
	
	let account = getAccount(address)
	let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)

	return charityCap.borrow()!.getIDs()
}
