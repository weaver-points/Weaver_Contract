use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use starknet::testing::set_block_timestamp;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};

use core::starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address
};

use weaver_contract::weaver::{IWeaverDispatcher, IWeaverDispatcherTrait, User};
use weaver_contract::weaver::{IERC721EXTDispatcherTrait, IERC721EXTDispatcher};


fn __setup__() -> ContractAddress {
    let nft_class_hash = declare("erc721").unwrap().contract_class().class_hash;
    let owner: ContractAddress = starknet::contract_address_const::<0x2bc02ae26b7>();
    let weaver_contract = declare("Weaver").unwrap().contract_class();
    let mut channel_constructor_calldata = array![(*(nft_class_hash)).into(), ((owner)).into()];
    let (weaver_contract_address, _) = weaver_contract
        .deploy(@channel_constructor_calldata)
        .unwrap_syscall();
    return weaver_contract_address;
}

#[test]
fn test_weaver_constructor() {
    let weaver_contract_address = __setup__();

    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let owner: ContractAddress = weaver_contract.owner();
    let erc721_contract: ContractAddress = weaver_contract.erc_721();

    assert_eq!(weaver_contract.owner(), owner);
    assert!(weaver_contract.erc_721() == erc721_contract, "wrong erc721 address");
}

