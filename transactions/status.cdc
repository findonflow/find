
import FIN from "../contracts/FIN.cdc."

transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FIN.status(tag)
        log(status)
    }

}
 
