import Admin from "../contracts/Admin.cdc"

transaction(typeIdentifier: String) {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth(BorrowValue)  AuthAccountAccount){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfoByTypeIdentifier(typeIdentifier) 
       
    }
}