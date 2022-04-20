import Admin from "../contracts/Admin.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(typeIdentifier: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfoByTypeIdentifier(typeIdentifier) 
       
    }
}