import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

//get all the views for an nft and address/path/id
pub fun main(address: Address, path:String, id: UInt64) : [String] {
	let pp = PublicPath(identifier: path)!
	let collection= getAccount(address).getCapability(pp).borrow<&{MetadataViews.ResolverCollection}>()!
	let nft=collection.borrowViewResolver(id: id)
	let views:[String]=[]
	for v in nft.getViews() {
		views.append(v.identifier)
	}
	return views
}

