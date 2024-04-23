import "Profile"


transaction() {
    prepare(account: auth(BorrowValue, Profile.Admin) &Account) {
        let wallet = account.storage.borrow<auth(Profile.Admin) &Profile.User>(from: Profile.storagePath)! 
        wallet.removeWallet("Flow")
        wallet.removeWallet("FUSD")
        wallet.removeWallet("USDC")
    }
}
