import "Admin"

transaction(typeIdentifier: String) {

    let adminRef : auth(Admin.Owner) &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }

    execute{

        self.adminRef.removeFTInfoByTypeIdentifier(typeIdentifier) 
       
    }
}
