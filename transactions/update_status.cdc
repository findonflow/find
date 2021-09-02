
import FIND from "../contracts/FIND.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
       FIND.janitor(tag)
    }
}
 
