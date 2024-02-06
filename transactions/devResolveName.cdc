import "Debug"
import "FIND"

transaction(user: String) {
    prepare(acct: auth(BorrowValue) &Account) {
        let name = FIND.resolve(user)
        Debug.log(name!.toString())
    }
}
