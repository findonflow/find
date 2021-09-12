
import FIND from "../contracts/FIND.cdc"

transaction(name: String) {

    prepare(account: AuthAccount) {
       FIND.janitor(name)
    }
}
 
