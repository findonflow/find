import FIN from "../contracts/FIN.cdc"

//Check the status of a fin user
pub fun main(tag: String) : UInt8 {
    let status=FIN.status(tag)
    return status.rawValue
}
