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
import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(name: String, user: Address) {

	prepare(account: AuthAccount) {

		let userAccount=getAccount(user)
		let profileCap = userAccount.getCapability<&{Profile.Public}>(Profile.publicPath)
		let leaseCollectionCap=userAccount.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!

		let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: 5.0) as! @FUSD.Vault

		adminClient.register(name: name, vault: <- payVault, profile: profileCap, leases: leaseCollectionCap)
	}
}


`;

/**
* Method to generate cadence code for registerAdmin transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const registerAdminTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `registerAdmin =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends registerAdmin transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const registerAdmin = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await registerAdminTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `registerAdmin =>`);
  reportMissing("signers", signers.length, 1, `registerAdmin =>`);

  return sendTransaction({code, ...props})
}