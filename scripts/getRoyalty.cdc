import Flovatar from 0x921ea449dffec68a
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(viewIdentifier: String) : AnyStruct? {

	// let address =FIND.resolve("bam")!

	// let collection= getAuthAccount(address).borrow<&Flovatar.Collection>(from: /storage/FlovatarCollection)!

	// let nft=collection.borrowViewResolver(id: collection.getIDs()[0])
	// for v in nft.getViews() {
	// 	if v.identifier== viewIdentifier {
	// 		return nft.resolveView(v)
	// 	}
	// }
	// return nft.getViews()
	let address =FIND.resolve("0x7c8995e83c4b1843")!
	let collectionCap= getAccount(address).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
	return collectionCap.getType()
	

}

