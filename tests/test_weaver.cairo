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
    ContractAddress, contract_address_const, get_block_timestamp, get_contract_address,
};

use weaver_contract::weaver::{IWeaverDispatcher, IWeaverDispatcherTrait, User};
use weaver_contract::weaver::{IERC721EXTDispatcher, IERC721EXTDispatcherTrait};

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

fn ADMIN() -> ContractAddress {
    'admin'.try_into().unwrap()
}

fn __deploy_weaver_NFT__() -> ContractAddress {
    let nft_class_hash = declare("erc721").unwrap().contract_class();
    let admin: ContractAddress = ADMIN();
    let mut events_constructor_calldata: Array<felt252> = array![];
    admin.serialize(ref events_constructor_calldata);
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

    // Set the weaver contract address in the ERC721 contract
    let nft = IERC721EXTDispatcher { contract_address: nft_address };
    start_cheat_caller_address(nft_address, ADMIN());
    nft.set_weaver_contract(contract_address);
    stop_cheat_caller_address(nft_address);

    (contract_address, nft_address)
}


#[test]
fn test_weaver_constructor() {
    let (weaver_contract_address, nft_address) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    assert_eq!(weaver_contract.owner(), OWNER());
    assert!(weaver_contract.erc_721() == nft_address, "wrong erc721 address");
}

#[test]
fn test_set_weaver_contract() {
    let (weaver_contract_address, _) = __setup__();
    let nft_contract = IERC721EXTDispatcher { contract_address: weaver_contract_address };

    let new_weaver_contract_address = 'new_weaver_contract_address'.try_into().unwrap();
    start_cheat_caller_address(weaver_contract_address, OWNER());
    nft_contract.set_weaver_contract(new_weaver_contract_address);
    stop_cheat_caller_address(weaver_contract_address);

    assert!(nft_contract.get_weaver_contract() == new_weaver_contract_address, "wrong weaver contract address");
}

#[test]
fn test_set_erc721() {
    let (weaver_contract_address, _) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let nft_address = __deploy_weaver_NFT__();
    start_cheat_caller_address(weaver_contract_address, OWNER());
    weaver_contract.set_erc721(nft_address);
    stop_cheat_caller_address(weaver_contract_address);

    assert!(weaver_contract.erc_721() == nft_address, "wrong erc721 address");
}

#[test]
fn test_register_user() {
    let (weaver_contract_address, _) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    stop_cheat_caller_address(weaver_contract_address);
}


#[test]
#[should_panic(expected: 'user already registered')]
fn test_already_registered_should_panic() {
    let (weaver_contract_address, _) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    
    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    // First registration should succeed
    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    // Second registration attempt with same address should fail
    let new_details: ByteArray = "Test User";
    weaver_contract.register_User(new_details);

    stop_cheat_caller_address(weaver_contract_address);
}
