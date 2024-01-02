
import Admin from "../contracts/Admin.cdc"

transaction(name: String, type: String) {


    prepare(account: auth(BorrowValue) &Account){

        let client= account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

        client.addPrivateForgeType(name: name, forgeType: CompositeType(type)!)

    }

}
