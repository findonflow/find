
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FiNS.status(tag)
        log(status)
    }

}
 
