import FIN from 0xf8d6e0586b0a20c7

pub fun main(tag: String) : UInt8 {
    let status=FIN.status(tag)
    log(status)
    return status.rawValue
}
