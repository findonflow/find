import Admin from "../contracts/Admin.cdc"

transaction(addon:String, price:UFix64) {

    let adminRef : &Admin.AdminProxy

    prepare(account: auth(BorrowValue) &Account){
        self.adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
        
    }
    execute{
        self.adminRef.setAddonPrice(name: addon, price: price)
    }
}
