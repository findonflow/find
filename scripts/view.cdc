import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

//Fetch a single view from a nft on a given path
pub fun main(address: Address, path:String, id: UInt64, identifier: String) : AnyStruct? {

	let pp = PublicPath(identifier:path)!
	let collection= getAccount(address).getCapability(pp).borrow<&{MetadataViews.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== identifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

