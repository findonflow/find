import Debug from "../contracts/Debug.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String) {
    prepare(acct: AuthAccount) {
        let name = FIND.resolve(user)
        Debug.log(name!.toString())
    }
}