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

transaction(name: String, amount: UFix64) {
	prepare(acct: AuthAccount) {

		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.listForSale(name: name, amount: amount)

	}
}

`;

/**
* Method to generate cadence code for sell transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const sellTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `sell =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends sell transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const sell = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await sellTemplate(addressMap);

  reportMissing("arguments", args.length, 2, `sell =>`);
  reportMissing("signers", signers.length, 1, `sell =>`);

  return sendTransaction({code, ...props})
}