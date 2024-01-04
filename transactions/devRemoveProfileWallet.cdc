import Profile from "../contracts/Profile.cdc"


transaction() {
    prepare(account: auth(BorrowValue, Profile.Owner) &Account) {
        let wallet = account.storage.borrow<auth(Profile.Owner) &Profile.User>(from: Profile.storagePath)! 
        wallet.removeWallet("Flow")
        wallet.removeWallet("FUSD")
        wallet.removeWallet("USDC")
    }
}
