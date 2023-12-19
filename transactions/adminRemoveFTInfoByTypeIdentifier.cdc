import Admin from "../contracts/Admin.cdc"

transaction(typeIdentifier: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfoByTypeIdentifier(typeIdentifier) 
       
    }
}