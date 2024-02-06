import "FindPack"
import "FIND"
import "NonFungibleToken"
import "FindAirdropper"
import "Admin"

transaction(packInfo: FindPack.AirdropInfo) {

    prepare(account: auth(BorrowValue) &Account) {

        let pathIdentifier = "FindPack_".concat(packInfo.packTypeName).concat("_").concat(packInfo.packTypeId.toString())

        let pathCollection = FindPack.getPacksCollection(packTypeName: packInfo.packTypeName, packTypeId: packInfo.packTypeId)
        let adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        let ids = pathCollection.getIDs()
        for i, user in packInfo.users {
            let id = ids[i]

            let address = FIND.resolve(user)
            if address == nil {
                panic("User cannot be resolved : ".concat(user))
            }

            let uAccount = getAccount(address!)
            let userPacks=uAccount.capabilities.borrow<&{NonFungibleToken.Receiver}>(FindPack.CollectionPublicPath) ?? panic("Could not find userPacks for ".concat(user))
            let pointer = adminRef.getAuthPointer(pathIdentifier: pathIdentifier, id: id)
            let ctx : {String : String } = {"message" : packInfo.message, "tenant" : "find"}
            FindAirdropper.safeAirdrop(pointer: pointer, receiver: address!, path: FindPack.CollectionPublicPath, context: ctx , deepValidation: true)
        }
    }
}


