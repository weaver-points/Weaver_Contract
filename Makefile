declare:
	sncast \
    declare \
    --fee-token eth \
	--url https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/CGmQDezuhKApBVtytny0Hh7MvAHwTh8- \
	--name ${name} \
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



	set_env:
	export STARKNET_ACCOUNT=
    export STARKNET_KEYSTORE= ../../keystore/keystore.json
    export STARKNET_RPC= https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/CGmQDezuhKApBVtytny0Hh7MvAHwTh8-


	sncast \                                                                                            
    account create \
	--url 'https://starknet-sepolia.g.alchemy.com/starknet/version/rpc/v0_7/CGmQDezuhKApBVtytny0Hh7MvAHwTh8- \'
    --name weaver_deploy

	