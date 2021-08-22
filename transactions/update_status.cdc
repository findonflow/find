
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
       FiNS.status(tag)
    }
}
 
