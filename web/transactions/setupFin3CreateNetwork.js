/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  
import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(leasePeriod: UFix64) {

	prepare(account: AuthAccount) {
		let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !wallet.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!
		adminClient.setWallet(wallet)
		adminClient.setPublicEnabled(true)
	}
}


`;

/**
* Method to generate cadence code for setupFin3CreateNetwork transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const setupFin3CreateNetworkTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `setupFin3CreateNetwork =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends setupFin3CreateNetwork transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const setupFin3CreateNetwork = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await setupFin3CreateNetworkTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `setupFin3CreateNetwork =>`);
  reportMissing("signers", signers.length, 1, `setupFin3CreateNetwork =>`);

  return sendTransaction({code, ...props})
}