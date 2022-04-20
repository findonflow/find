import Admin from "../contracts/Admin.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

transaction(alias: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeNFTInfoByAlias(alias)
        
    }
}