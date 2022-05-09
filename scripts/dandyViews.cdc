import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import Dandy from "../contracts/Dandy.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"


pub fun main(name: String, id: UInt64) : [String] {
	let address =FIND.lookupAddress(name)!
	let collection= getAccount(address).getCapability(Dandy.CollectionPublicPath).borrow<&{MetadataViews.ResolverCollection}>()!
	let nft=collection.borrowViewResolver(id: id)
	let views:[String]=[]
	for v in nft.getViews() {
		views.append(v.identifier)
	}
	return views
}

