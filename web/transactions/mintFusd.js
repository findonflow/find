/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  

import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(recipient: Address, amount: UFix64) {
	let tokenAdmin: &FUSD.Administrator
	let tokenReceiver: &{FungibleToken.Receiver}

	prepare(signer: AuthAccount) {

		self.tokenAdmin = signer
		.borrow<&FUSD.Administrator>(from: /storage/fusdAdmin)
		?? panic("Signer is not the token admin")

		self.tokenReceiver = getAccount(recipient)
		.getCapability(/public/fusdReceiver)
		.borrow<&{FungibleToken.Receiver}>()
		?? panic("Unable to borrow receiver reference")
	}

	execute {



		let minter <- self.tokenAdmin.createNewMinter()
		let mintedVault <- minter.mintTokens(amount: amount)

		self.tokenReceiver.deposit(from: <-mintedVault)

		destroy minter
	}
}

`;

/**
* Method to generate cadence code for mintFusd transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const mintFusdTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `mintFusd =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends mintFusd transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const mintFusd = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await mintFusdTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `mintFusd =>`);
  reportMissing("signers", signers.length, 1, `mintFusd =>`);

  return sendTransaction({code, ...props})
}