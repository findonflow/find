all: dev

.PHONY: setup
setup: deploy
	go run ./tasks/setup/main.go

#this goal deployes all the contracts to emulator
.PHONY: deploy
deploy:
	flow project deploy 


.PHONY: emulator
emulator:
	flow project start-emulator -v


.phony: test
test:
	gotessum -f testname

.phony: dev
dev:
	gotestsum -f testname --watch
