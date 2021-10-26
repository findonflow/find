import Profile from "../contracts/Profile.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"

pub fun main(address: Address) : [String] {

	let account=getAccount(address)

	let profileCap= getAccount(address).getCapability<&{Profile.Public}>(Profile.publicPath)

	if !profileCap.check() {
		return ["Unknown, no profile created"]
	}

	let collections= profileCap.borrow()!.getCollections()

	var names:  [String] = []
	for col in collections {
		if col.type == Type<&{TypedMetadata.ViewResolverCollection}>() {
			names.append(col.name)
		}
	}
	return names

}

