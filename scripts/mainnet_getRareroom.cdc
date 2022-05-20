import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import FIND from "../contracts/FIND.cdc"
import RareRooms_NFT from 0x329feb3ab062d289


pub fun main(user: String) : {String:String} {

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return {}}
	let address = resolveAddress!
	let account=getAccount(address)
	let rareRoomCap = account.getCapability<&RareRooms_NFT.Collection{RareRooms_NFT.RareRooms_NFTCollectionPublic}>(RareRooms_NFT.CollectionPublicPath)

	if rareRoomCap.check() {
		let collection = rareRoomCap.borrow()!
		let items: [String] = []
		for id in collection.getIDs() {
			let nft = collection.borrowRareRooms_NFT(id: id)!
			let metadata = RareRooms_NFT.getSetMetadata(setId: nft.setId)!
			return metadata
		}
	}
	return {}
}
