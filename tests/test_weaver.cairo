use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use starknet::testing::set_block_timestamp;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use core::byte_array::ByteArray;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};

use core::starknet::{
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address
};

use weaver_contract::weaver::{IWeaverDispatcher, IWeaverDispatcherTrait, User};
use weaver_contract::weaver::{IERC721EXTDispatcherTrait, IERC721EXTDispatcher};

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

const ADMIN: felt252 = 'ADMIN';

fn __deploy_weaver_NFT__() -> ContractAddress {
    let nft_class_hash = declare("erc721").unwrap().contract_class();

    let mut events_constructor_calldata: Array<felt252> = array![ADMIN];
    let (nft_contract_address, _) = nft_class_hash.deploy(@events_constructor_calldata).unwrap();

    return (nft_contract_address);
}

fn __setup__() -> (ContractAddress, ContractAddress) {
    let class_hash = declare("Weaver").unwrap().contract_class();
    
    let nft_address = __deploy_weaver_NFT__();

    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    nft_address.serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();

    (contract_address, nft_address)
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


#[test]
#[should_panic(expected: ('user already registered',))]
fn test_registration_check() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    
    let user: ContractAddress = contract_address_const::<0x123>();
    start_cheat_caller_address(weaver_contract_address, user);
    
    // First registration should succeed
    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(weaver_contract_address);

    assert!(is_registered.Details == details, "User should be registered");
    
    // Second registration should fail with 'user already registered'
    let new_details: ByteArray = "Test User";
    weaver_contract.register_User(new_details);
    
    stop_cheat_caller_address(weaver_contract_address);
}

