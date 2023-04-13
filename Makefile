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

bump:
	go run tasks/bumpVersion/main.go

client: gen-client
	./dappertx testnet
	./dappertx mainnet

compare-client:
	FLOW_NETWORK=testnet FOLDER_PATH=$(arg) go run ./tasks/checkDapperTx/main.go
	FLOW_NETWORK=mainnet FOLDER_PATH=$(arg) go run ./tasks/checkDapperTx/main.go



