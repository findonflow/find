import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction(dapperAddress:Address) {

	prepare(acct: AuthAccount) {
		// Get a Receiver reference for the Dapper account that will be the recipient of the forwarded DUC
		let dapper = getAccount(dapperAddress)
	  let dapperDUCReceiver = dapper.getCapability(/public/dapperUtilityCoinReceiver)

	  // Create a new Forwarder resource for DUC and store it in the new account's storage
	  let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
	  acct.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)

	  // Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
	  acct.link<&{FungibleToken.Receiver}>(
      /public/dapperUtilityCoinReceiver,
      target: /storage/dapperUtilityCoinReceiver
	  )
	}
}