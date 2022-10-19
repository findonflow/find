all: dev

.PHONY: setup deploy emulator test dev contract contract_publish client lint

setup: deploy
	go run ./tasks/setup/main.go

lint:
	golangci-lint run 

#this goal deployes all the contracts to emulator
deploy:
	flow project deploy 

emulator:
	flow emulator -v

test:
	gotessum -f testname

dev:
	gotestsum -f testname --watch

gen-client: 
	go run tasks/client/main.go > lib/find.json

publish:
	cd lib && npm publish --access public && cd ..

patch:
	json-bump lib/package.json --patch

minor:
	json-bump lib/package.json --minor

major:
	json-bump lib/package.json --major

update-overflow: 
	go get github.com/bjartek/overflow@v1.0.2
	go mod tidy

client: gen-client client-dapper-mainnet
	jq ".networks.testnet.transactions.createProfileDapper.code" lib/find.json -r > dapper-tx/testnet/createProfile.cdc
	jq ".networks.testnet.transactions.buyLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/testnet/buyLeaseForSale.cdc
	jq ".networks.testnet.transactions.buyAddonDapper.code" lib/find.json -r > dapper-tx/testnet/buyAddon.cdc
	jq ".networks.testnet.transactions.editProfileDapper.code" lib/find.json -r > dapper-tx/testnet/editProfile.cdc
	jq ".networks.testnet.transactions.listLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/testnet/listLeaseForSale.cdc
	jq ".networks.testnet.transactions.moveNameToDapper.code" lib/find.json -r > dapper-tx/testnet/moveNameTo.cdc
	jq ".networks.testnet.transactions.registerDapper.code" lib/find.json -r > dapper-tx/testnet/register.cdc
	jq ".networks.testnet.transactions.removeRelatedAccountDapper.code" lib/find.json -r > dapper-tx/testnet/removeRelatedAccount.cdc
	jq ".networks.testnet.transactions.renewNameDapper.code" lib/find.json -r > dapper-tx/testnet/renewName.cdc
	jq ".networks.testnet.transactions.setPrivateModeDapper.code" lib/find.json -r > dapper-tx/testnet/setPrivateMode.cdc
	jq ".networks.testnet.transactions.setRelatedAccountDapper.code" lib/find.json -r > dapper-tx/testnet/setRelatedAccount.cdc
	jq ".networks.testnet.scripts.getMetadataForBuyAddonDapper.code" lib/find.json -r > dapper-tx/testnet/getMetadataForBuyAddon.cdc
	jq ".networks.testnet.scripts.getMetadataForBuyLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/testnet/getMetadataForBuyLeaseForSale.cdc
	jq ".networks.testnet.scripts.getMetadataForRegisterDapper.code" lib/find.json -r > dapper-tx/testnet/getMetadataForRegister.cdc
	jq ".networks.testnet.scripts.getMetadataForRenewNameDapper.code" lib/find.json -r > dapper-tx/testnet/getMetadataForRenewName.cdc

client-dapper-mainnet:
	jq ".networks.mainnet.transactions.createProfileDapper.code" lib/find.json -r > dapper-tx/mainnet/createProfile.cdc
	jq ".networks.mainnet.transactions.buyLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/mainnet/buyLeaseForSale.cdc
	jq ".networks.mainnet.transactions.buyAddonDapper.code" lib/find.json -r > dapper-tx/mainnet/buyAddon.cdc
	jq ".networks.mainnet.transactions.editProfileDapper.code" lib/find.json -r > dapper-tx/mainnet/editProfile.cdc
	jq ".networks.mainnet.transactions.listLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/mainnet/listLeaseForSale.cdc
	jq ".networks.mainnet.transactions.moveNameToDapper.code" lib/find.json -r > dapper-tx/mainnet/moveNameTo.cdc 
	jq ".networks.mainnet.transactions.registerDapper.code" lib/find.json -r > dapper-tx/mainnet/register.cdc
	jq ".networks.mainnet.transactions.removeRelatedAccountDapper.code" lib/find.json -r > dapper-tx/mainnet/removeRelatedAccount.cdc
	jq ".networks.mainnet.transactions.renewNameDapper.code" lib/find.json -r > dapper-tx/mainnet/renewName.cdc
	jq ".networks.mainnet.transactions.setPrivateModeDapper.code" lib/find.json -r > dapper-tx/mainnet/setPrivateMode.cdc
	jq ".networks.mainnet.transactions.setRelatedAccountDapper.code" lib/find.json -r > dapper-tx/mainnet/setRelatedAccount.cdc
	jq ".networks.mainnet.scripts.getMetadataForBuyAddonDapper.code" lib/find.json -r > dapper-tx/mainnet/getMetadataForBuyAddon.cdc
	jq ".networks.mainnet.scripts.getMetadataForBuyLeaseForSaleDapper.code" lib/find.json -r > dapper-tx/mainnet/getMetadataForBuyLeaseForSale.cdc
	jq ".networks.mainnet.scripts.getMetadataForRegisterDapper.code" lib/find.json -r > dapper-tx/mainnet/getMetadataForRegister.cdc
	jq ".networks.mainnet.scripts.getMetadataForRenewNameDapper.code" lib/find.json -r > dapper-tx/mainnet/getMetadataForRenewName.cdc



