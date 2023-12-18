import Admin from "../contracts/Admin.cdc"

transaction(name: String, addon: String){
    prepare(account: auth(BorrowValue) &Account){
        let adminRef = account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")

        adminRef.addAddon(name: name, addon: addon)
    }
}

