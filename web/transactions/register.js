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
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String) {
	prepare(acct: AuthAccount) {

		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)

		let price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(price.toString()))

		let vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")
		let payVault <- vaultRef.withdraw(amount: price) as! @FUSD.Vault

		let leaseCollectionCap=acct.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollectionCap.check() {
			let finLeases <- FIND.createEmptyLeaseCollection()
			acct.save(<- finLeases, to: FIND.LeaseStoragePath)
			acct.link<&{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let leases=acct.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!
		leases.register(name: name, vault: <- payVault)

	}
}

`;

/**
* Method to generate cadence code for register transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const registerTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `register =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends register transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const register = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await registerTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `register =>`);
  reportMissing("signers", signers.length, 1, `register =>`);

  return sendTransaction({code, ...props})
}