import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

pub fun main(user: Address): AnyStruct {
    let authAccount: AuthAccount = getAuthAccount(user)
    let paths: [String] = []

    let iterateFunc: ((StoragePath, Type): Bool) = fun (path: StoragePath, type: Type): Bool {
        if type.isSubtype(of: Type<@NonFungibleToken.Collection>()) {
			paths.append(path.toString())
        }
        return true
    }

    authAccount.forEachStored(iterateFunc)

    return paths
}
