import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(alias: String) {

    let adminRef : &FTRegistry.Admin

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&FTRegistry.Admin>(from: FTRegistry.FTRegistryStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{
        if let typeIdentifier = FTRegistry.getTypeIdentifier(alias: alias) {
           self.adminRef.removeFTInfo(typeIdentifier: typeIdentifier) 
        }
        
    }
}