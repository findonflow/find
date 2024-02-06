
import "Admin"

transaction(name: String, type: String) {


    prepare(account: auth(BorrowValue) &Account){

        let client= account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

        client.addPrivateForgeType(name: name, forgeType: CompositeType(type)!)

    }

}
