import LostAndFoundHelper from "../contracts/standard/LostAndFoundHelper.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String, specificType: String?) : Report {

	if let address = FIND.resolve(user) {
		var type = Type<@NonFungibleToken.NFT>()
		if specificType != nil {
			let runTimeType = CompositeType(specificType!) 
			if runTimeType == nil {
				return logErr("Cannot composite run time type. Type : ".concat(specificType!))
			}
			type = runTimeType!
		}

		let ticketInfo = FindLostAndFoundWrapper.getTickets(user: address, specificType: type)
		return Report(ticketInfo : ticketInfo, error: nil)
	}
	return logErr("Cannot resolve user. User : ".concat(user))
}


pub struct Report {

	pub let ticketInfo : {String : [LostAndFoundHelper.Ticket]}
	pub let tickets : {String : [UInt64]}
	pub let error : String?

	init(ticketInfo : {String : [LostAndFoundHelper.Ticket]}, error: String?) {
		self.ticketInfo = ticketInfo
		let allTickets : {String : [UInt64]} = {}
		let tickets : [UInt64] = []
		for type in ticketInfo.keys {
			for ticket in ticketInfo[type]! {
				if ticket.ticketID != nil {
					tickets.append(ticket.ticketID!)
				}
			}
			allTickets.insert(key: type, tickets)
		}
		self.tickets = allTickets
		self.error = error
	}
}

pub fun logErr(_ err: String) : Report {
	return Report(ticketInfo : {}, error: err)
}