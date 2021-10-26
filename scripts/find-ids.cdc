import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

pub fun main(address: Address, path: PublicPath) : [UInt64] {

	let account=getAccount(address)
	return account.getCapability(path).borrow<&{TypedMetadata.ViewResolverCollection}>()!.getIDs()

}

