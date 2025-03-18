declare:
	sncast \
    declare \
    --fee-token eth \
    --contract-name ${name}

deploy:
	sncast deploy --fee-token eth --class-hash ${classhash} --constructor-calldata ${arg}


t:
	export SNFORGE_BACKTRACE=1 && snforge test

upgrade:
	sncast \
	invoke \
	--fee-token eth \
	--contract-address ${address} \
	--function "upgrade" \
	--calldata ${calldata}