use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto};
use core::byte_array::ByteArray;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use starknet::{ContractAddress, get_block_timestamp};

use weaver_contract::mods::interfaces::IWeaver::{IWeaverDispatcher, IWeaverDispatcherTrait};
use weaver_contract::mods::interfaces::IWeaverNFT::{
    IWeaverNFTDispatcher, IWeaverNFTDispatcherTrait
};
use weaver_contract::mods::events::{UserRegistered, TaskMinted};
use weaver_contract::mods::weaver_contract::weaver::Weaver::{Event};


fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

fn __setup__() -> ContractAddress {
    let class_hash = declare("Weaver").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();
    let nft_address = __deploy_WeaverNFT__(contract_address);
    let weaver_contract = IWeaverDispatcher { contract_address: contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    weaver_contract.set_erc721(nft_address);
    stop_cheat_caller_address(contract_address);

    return contract_address;
}

fn __deploy_WeaverNFT__(admin: ContractAddress) -> ContractAddress {
    let nft_class_hash = declare("WeaverNFT").unwrap().contract_class();
    let mut calldata = array![];
    admin.serialize(ref calldata);

    let (nft_contract_address, _) = nft_class_hash.deploy(@calldata).unwrap();

    return (nft_contract_address);
}


#[test]
fn test_weaver_constructor() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    assert_eq!(weaver_contract.owner(), OWNER());
}


#[test]
fn test_register_user() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    stop_cheat_caller_address(weaver_contract_address);
}


// #[test]
// fn test_register_user_emit_event() {
//     let weaver_contract_address = __setup__();
//     let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

//     let mut spy = spy_events();

//     let user: ContractAddress = USER();
//     start_cheat_caller_address(weaver_contract_address, user);

//     let details: ByteArray = "Test User";
//     weaver_contract.register_User(details);

//     let is_registered = weaver_contract.get_register_user(user);
//     assert!(is_registered.Details == "Test User", "User should be registered");

//     let expected_event = Event::UserRegistered(UserRegistered { user: user });
//     spy.assert_emitted(@array![(weaver_contract_address, expected_event)]);

//     stop_cheat_caller_address(weaver_contract_address);
// }

#[test]
#[should_panic(expected: 'USER_ALREADY_REGISTERED')]
fn test_already_registered_should_panic() {
    let weaver_contract_address = __setup__();
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


#[test]
fn test_nft_was_minted_after_user_registers() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let minted_token_id = nft_dispatcher.get_user_token_id(user);
    assert!(minted_token_id > 0, "NFT NOT Minted!");

    let last_minted_id = nft_dispatcher.get_last_minted_id();
    assert_eq!(minted_token_id, last_minted_id, "Minted token ID should match the last minted ID");

    let mint_timestamp = nft_dispatcher.get_token_mint_timestamp(minted_token_id);
    let current_block_timestamp = get_block_timestamp();
    assert_eq!(mint_timestamp, current_block_timestamp, "Mint timestamp not matched");

    stop_cheat_caller_address(weaver_contract_address);
}

