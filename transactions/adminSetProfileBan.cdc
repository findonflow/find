import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String) {
    prepare(account: auth(BorrowValue) &Account) {
        let profile =account.storage.borrow<&Profile.User>(from:Profile.storagePath)!
        let address =FIND.resolve(user) ?? panic("Not a registered name or valid address.")
        profile.addBan(address)
    }
}

