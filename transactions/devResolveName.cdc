import Debug from "../contracts/Debug.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String) {
    prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
        let name = FIND.resolve(user)
        Debug.log(name!.toString())
    }
}