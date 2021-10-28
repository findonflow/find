#/bin/bash

FLOW_TRANSACTIONS_DIR="../flow-transactions-find/transactions/Find"
mapfile -t arr < <( jq '.transactions | keys[]' lib/find.json -r )


rm  $FLOW_TRANSACTIONS_DIR/*.cdc

for i in "${arr[@]}"
do
	jq --arg tx "$i" '.transactions[$tx]' lib/find.json -r > $FLOW_TRANSACTIONS_DIR/$i.cdc
done


cd $FLOW_TRANSACTIONS_DIR
rm -Rf setup*
rm -Rf clock*
rm -Rf registerAdmin*
rm -Rf mint_fusd*
rm -Rf status*

gsed -i 's/0xTypedMetadata/0xFIND_ADDRESS/g' *.cdc
gsed -i 's/0xArtifact/0xFIND_ADDRESS/g' *.cdc
gsed -i 's/0xProfile/0xVERSUS_ADDRESS/g' *.cdc
gsed -i 's/0xFlowToken/0xFLOW_TOKEN_ADDRESS/g' *.cdc
gsed -i 's/0xFUSD/0xFUSD_ADDRESS/g' *.cdc
gsed -i 's/0xFungibleToken/0xFUNGIBLE_TOKEN_ADDRESS/g' *.cdc
gsed -i 's/0xFIND/0xFIND_ADDRESS/g' *.cdc


cd
