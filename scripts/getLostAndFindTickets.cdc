import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String , type: Type) : [UInt64] {

    if let address = FIND.resolve(user) {
        let tickets = LostAndFound.borrowAllTicketsByType(addr: address, type: type)
        let ticketIDs : [UInt64] = []
        for ticket in tickets {
            if !ticket.itemType().isInstance(type) {
                continue
            }

            ticketIDs.append(ticket.uuid)
        }
        return ticketIDs
    }
    return []
}