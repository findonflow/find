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


/*
  This script will check an address and print out its FT, NFT and Versus resources
 */
pub fun main() :UFix64 {

    log(FIND.status("0xb"))
    return FIND.calculateCost("0xb")
}

`;

/**
* Method to generate cadence code for TestAsset
* @param {Object.<string, string>} addressMap - contract name as a key and address where it's deployed as value
*/
export const checkFinTemplate = async (addressMap = {}) => {
  const envMap = await getEnvironment();
  const fullMap = {
  ...envMap,
  ...addressMap,
  };

  // If there are any missing imports in fullMap it will be reported via console
  reportMissingImports(CODE, fullMap, `checkFin =>`)

  return replaceImportAddresses(CODE, fullMap);
};

export const checkFin = async (props) => {
  const { addressMap = {}, args = [] } = props
  const code = await checkFinTemplate(addressMap);

  reportMissing("arguments", args.length, 0, `checkFin =>`);

  return executeScript({code, ...props})
}