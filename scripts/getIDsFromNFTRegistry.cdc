import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

//get all the views for an nft and address/path/id
pub fun main(user: String) : {String: [UInt64]} {

	let resolveAddress=FIND.resolve(user)
	if resolveAddress == nil {
		return {}
	}

	let address = resolveAddress!

	let account= getAccount(address)
	let registryData = NFTRegistry.getNFTInfoAll()

	let collections : {String:[UInt64]} ={}
	for key in registryData.keys {
		let item = registryData[key]!

		let cap = account.getCapability(item.publicPath).borrow<&{MetadataViews.ResolverCollection}>()!
		let ids=cap.getIDs()
		let alias=item.alias
		if ids.length != 0 {
			collections[alias]=cap.getIDs()
		}
	}
	return collections
}

