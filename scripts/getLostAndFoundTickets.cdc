import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String , type: String) : [UInt64] {

    if let address = FIND.resolve(user) {
        let runTimeType = CompositeType(type)!
        let tickets = LostAndFound.borrowAllTicketsByType(addr: address, type: runTimeType)
        let ticketIDs : [UInt64] = []
        for ticket in tickets {
            if !ticket.itemType().isSubtype(of: runTimeType) {
                continue
            }

            ticketIDs.append(ticket.uuid)
        }
        return ticketIDs
    }
    return []
}