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

transaction(name: String) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)!
		bids.cancelBid(name)
	}
}

`;

/**
* Method to generate cadence code for cancelBid transaction
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const cancelBidTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `cancelBid =>`)

  return replaceImportAddresses(CODE, fullMap);
};


/**
* Sends cancelBid transaction to the network
* @param {Object.<string, string>} props.addressMap - contract name as a key and address where it's deployed as value
* @param Array<*> props.args - list of arguments
* @param Array<*> props.signers - list of signers
*/
export const cancelBid = async (props) => {
  const { addressMap, args = [], signers = [] } = props;
  const code = await cancelBidTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `cancelBid =>`);
  reportMissing("signers", signers.length, 1, `cancelBid =>`);

  return sendTransaction({code, ...props})
}