
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
       FiNS.janitor(tag)
    }
}
 
