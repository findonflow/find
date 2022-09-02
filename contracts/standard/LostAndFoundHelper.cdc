import LostAndFound from "./LostAndFound.cdc"

pub contract LostAndFoundHelper {

    pub struct Ticket {

        // An optional message to attach to this item.
        pub let memo: String?
        // The address that it allowed to withdraw the item fromt this ticket
        pub let redeemer: Address
        //The type of the resource (non-optional) so that bins can represent the true type of an item
        pub let type: Type
        pub let typeIdentifier: String
        // State maintained by LostAndFound
        pub let redeemed: Bool
        pub let name : String?
        pub let description : String?
        pub let thumbnail : String?
        pub let ticketID : UInt64?

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

    pub fun constructResult(_ ticket: &LostAndFound.Ticket?, id:UInt64?) : LostAndFoundHelper.Ticket? {
        if ticket != nil {
            return LostAndFoundHelper.Ticket(ticket!, id: id)
        }
        return nil
    }

}