use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use starknet::testing::set_block_timestamp;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use core::byte_array::ByteArray;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait, get_class_hash
};

use openzeppelin::{token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait}};

use starknet::{ContractAddress, ClassHash, get_block_timestamp};

use weaver_contract::interfaces::IWeaverNFT::{IWeaverNFTDispatcher, IWeaverNFTDispatcherTrait};
use weaver_contract::interfaces::IWeaver::{IWeaverDispatcher, IWeaverDispatcherTrait, User};

const ADMIN: felt252 = 'ADMIN';

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

fn __setup__() -> (ContractAddress, ContractAddress) {
    let class_hash = declare("Weaver").unwrap().contract_class();

    let nft_address = __deploy_WeaverNFT__();

    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    nft_address.serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();

    (contract_address, nft_address)
}

fn __deploy_WeaverNFT__() -> ContractAddress {
    let nft_class_hash = declare("WeaverNFT").unwrap().contract_class();

    let mut events_constructor_calldata: Array<felt252> = array![ADMIN];
    let (nft_contract_address, _) = nft_class_hash.deploy(@events_constructor_calldata).unwrap();

    return (nft_contract_address);
}


#[test]
fn test_weaver_constructor() {
    let (weaver_contract_address, nft_address) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    assert_eq!(weaver_contract.owner(), OWNER());
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

// #[test]
// fn test_protocol_register() {
//     let (weaver_contract_address, nft_address) = __setup__();
//     let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

//     let user: ContractAddress = USER();
//     start_cheat_caller_address(weaver_contract_address, user);

//     let protocol_name: ByteArray = "Weaver Protocol";
//     weaver_contract.protocol_register(protocol_name);

//     let protocol_info = weaver_contract.get_registered_protocols(user);
//     assert!(protocol_info.protocol_name == "Weaver Protocol", "Protocol should be registered");

//     stop_cheat_caller_address(weaver_contract_address);
// }

#[test]
fn test_nft_minted_on_protocol_register() {
    let (weaver_contract_address, nft_address) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: nft_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let protocol_name: ByteArray = "Weaver Protocol";
    weaver_contract.protocol_register(protocol_name);

    let minted_token_id = nft_dispatcher.get_user_token_id(user);
    assert!(minted_token_id > 0, "NFT NOT Minted!");

   
    let last_minted_id = nft_dispatcher.get_last_minted_id();
    assert_eq!(minted_token_id, last_minted_id, "Minted token ID should match the last minted ID");

    let mint_timestamp = nft_dispatcher.get_token_mint_timestamp(minted_token_id);
    let current_block_timestamp = get_block_timestamp();
    assert_eq!(mint_timestamp, current_block_timestamp, "Mint timestamp not matched");

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: 'PROTOCOL_ALREADY_REGISTERED')]
fn test_protocol_register_already_registered() {
    let (weaver_contract_address, nft_address) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let protocol_name: ByteArray = "Weaver Protocol";
    weaver_contract.protocol_register(protocol_name);

    weaver_contract.protocol_register("Weaver Protocol");

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: 'INVALID_PROTOCOL_NAME')]
fn test_invalid_protocol_name_should_panic() {
    let (weaver_contract_address, _) = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let invalid_protocol_name: ByteArray = ""; // Empty protocol name
    weaver_contract.protocol_register(invalid_protocol_name);

    stop_cheat_caller_address(weaver_contract_address);
}