/** pragma type script **/

import {
  getEnvironment,
  replaceImportAddresses,
  reportMissingImports,
  reportMissing,
  executeScript
} from 'flow-cadut'

export const CODE = `
  import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIND.LeaseInformation] {

	  let leaseCollection = getAccount(user).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		return leaseCollection.borrow()!.getLeaseInformation()
}

`;

/**
* Method to generate cadence code for TestAsset
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const leaseStatusTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `leaseStatus =>`)

  return replaceImportAddresses(CODE, fullMap);
};

export const leaseStatus = async (props) => {
  const { addressMap = {}, args = [] } = props
  const code = await leaseStatusTemplate(addressMap);

  reportMissing("arguments", args.length, 1, `leaseStatus =>`);

  return executeScript({code, ...props})
}