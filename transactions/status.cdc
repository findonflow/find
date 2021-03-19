
//emulator
import FIN from 0xf8d6e0586b0a20c7
transaction(tag: String) {

    prepare(account: AuthAccount) {
        let status=FIN.status(tag)
        log(status)
    }

}
 