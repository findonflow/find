/** pragma type transaction **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  sendTransaction
} from 'flow-cadut'

export const CODE = `
  import FIND from "../contracts/FIND.cdc"

transaction(owner: Address, name: String) {
	prepare(account: AuthAccount) {

		let leaseCollection = getAccount(owner).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		leaseCollection.borrow()!.fullfillAuction(name)

	}
}

`;

/**
* Method to generate cadence code for fullfillAuction transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const fullfillAuctionTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `fullfillAuction =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends fullfillAuction transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const fullfillAuction = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await fullfillAuctionTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `fullfillAuction =>`);
  reportMissing("signers", signers.length, 1, `fullfillAuction =>`);

  return sendTransaction({code, ...props})
}