import LostAndFound from "./LostAndFound.cdc"

access(all) contract LostAndFoundHelper {

    access(all) struct Ticket {

        // An optional message to attach to this item.
        access(all) let memo: String?
        // The address that it allowed to withdraw the item fromt this ticket
        access(all) let redeemer: Address
        //The type of the resource (non-optional) so that bins can represent the true type of an item
        access(all) let type: Type
        access(all) let typeIdentifier: String
        // State maintained by LostAndFound
        access(all) let redeemed: Bool
        access(all) let name : String?
        access(all) let description : String?
        access(all) let thumbnail : String?
        access(all) let ticketID : UInt64?

        init(_ ticket: &LostAndFound.Ticket, id: UInt64?) {
            self.memo = ticket.memo 
            self.redeemer = ticket.redeemer 
            self.type = ticket.type 
            self.typeIdentifier = ticket.type.identifier
            self.redeemed = ticket.redeemed 
            self.name = ticket.display?.name
            self.description = ticket.display?.description
            self.thumbnail = ticket.display?.thumbnail?.uri()
            self.ticketID = id
        }

    }

    access(all) constructResult(_ ticket: &LostAndFound.Ticket?, id:UInt64?) : LostAndFoundHelper.Ticket? {
        if ticket != nil {
            return LostAndFoundHelper.Ticket(ticket!, id: id)
        }
        return nil
    }

}