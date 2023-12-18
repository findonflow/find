import Admin from "../contracts/Admin.cdc"

transaction(alias: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth(BorrowValue)  AuthAccountAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfoByAlias(alias)

    }
}
 