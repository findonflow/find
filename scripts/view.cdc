import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

//Fetch a single view from a nft on a given path
pub fun main(address: Address, path:PublicPath, id: UInt64, identifier: String) : AnyStruct? {

	let collection= getAccount(address).getCapability(path).borrow<&{MetadataViews.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== identifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

