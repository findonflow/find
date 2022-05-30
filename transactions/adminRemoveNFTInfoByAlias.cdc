import Admin from "../contracts/Admin.cdc"

transaction(alias: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeNFTInfoByAlias(alias)
        
    }
}