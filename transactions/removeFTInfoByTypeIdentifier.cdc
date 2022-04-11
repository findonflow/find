import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(typeIdentifier: String) {

    let adminRef : &FTRegistry.Admin

    prepare(account: AuthAccount){
        self.adminRef = account.borrow<&FTRegistry.Admin>(from: FTRegistry.FTRegistryStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfo(typeIdentifier: typeIdentifier) 
       
    }
}