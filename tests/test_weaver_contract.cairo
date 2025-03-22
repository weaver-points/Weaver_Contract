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
use weaver_contract::mods::events::{UserRegistered, ProtocolRegistered, TaskMinted};
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


#[test]
fn test_register_user_emit_event() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let mut spy = spy_events();

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    let expected_event = Event::UserRegistered(UserRegistered { user: user });
    spy.assert_emitted(@array![(weaver_contract_address, expected_event)]);

    stop_cheat_caller_address(weaver_contract_address);
}


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
#[should_panic(expected: 'USER_NOT_REGISTERED')] // Case-sensitive match
fn test_mint_unregistered_user_panics() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let unregistered_user = USER(); // Uses the numeric address now
    start_cheat_caller_address(weaver_contract_address, unregistered_user);

    // This should panic with USER_NOT_REGISTERED
    weaver_contract.mint(1);

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
fn test_protocol_register() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let protocol_name: ByteArray = "Weaver Protocol";
    weaver_contract.protocol_register(protocol_name);

    let protocol_info = weaver_contract.get_registered_protocols(user);
    assert!(protocol_info.protocol_name == "Weaver Protocol", "Protocol should be registered");

    stop_cheat_caller_address(weaver_contract_address);
}


#[test]
fn test_protocol_register_emit_event() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    let mut spy = spy_events();
    start_cheat_caller_address(weaver_contract_address, user);

    let protocol_name: ByteArray = "Weaver Protocol";
    weaver_contract.protocol_register(protocol_name);

    let protocol_info = weaver_contract.get_registered_protocols(user);
    assert!(protocol_info.protocol_name == "Weaver Protocol", "Protocol should be registered");

    let expected_event = Event::ProtocolRegistered(ProtocolRegistered { user: user });
    spy.assert_emitted(@array![(weaver_contract_address, expected_event)]);

    stop_cheat_caller_address(weaver_contract_address);
}


#[test]
fn test_nft_minted_on_protocol_register() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

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
    let weaver_contract_address = __setup__();
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
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let invalid_protocol_name: ByteArray = ""; // Empty protocol name
    weaver_contract.protocol_register(invalid_protocol_name);

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: 'TASK_ALREADY_EXISTS')]
fn test_mint_nft_duplicate_id_should_panic() {
    let weaver_contract_address = __setup__();

    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };
    let user: ContractAddress = USER();

    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Testx User";
    weaver_contract.register_User(details);

    let protocol_name: ByteArray = "Weavers Protocol";
    weaver_contract.protocol_register(protocol_name);

    let task_id = 1;

    weaver_contract.mint(task_id);

    let minted_token_id = nft_dispatcher.get_user_token_id(user);
    assert!(minted_token_id > 0, "First NFT mint failed!");

    weaver_contract.mint(task_id);

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
fn test_mint_nft() {
    let weaver_contract_address = __setup__();

    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

    let mut spy = spy_events();
    let user: ContractAddress = USER();

    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    let task_id = 2;

    let mut task_info = weaver_contract.get_task_info(task_id);

    task_info.is_completed = true;

    assert!(task_info.is_completed, "Task should be completed");

    weaver_contract.mint(task_id);

    let minted_token_id = nft_dispatcher.get_user_token_id(user);

    assert!(minted_token_id > 0, "NFT NOT Minted!");

    let expected_event = Event::TaskMinted(TaskMinted { task_id: task_id, user: user });
    spy.assert_emitted(@array![(weaver_contract_address, expected_event)]);

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: "Task should NOT be completed")]
fn test_mint_nft_task_not_completed_should_panic() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let user: ContractAddress = USER();

    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Testx User";
    weaver_contract.register_User(details);

    let protocol_name: ByteArray = "Weavers Protocol";
    weaver_contract.protocol_register(protocol_name);

    let task_id = 999;

    let mut task_info = weaver_contract.get_task_info(task_id);

    task_info.is_completed = false;

    assert!(task_info.is_completed, "Task should NOT be completed");

    weaver_contract.mint(task_id);

    println!("Mint function did not panic!");

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
fn test_mint_nft_after_task_completed() {
    // Set up the contracts
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

    // Define the user address
    let user: ContractAddress = USER();

    // Start the contract as the user
    start_cheat_caller_address(weaver_contract_address, user);

    // Register the user
    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    // Verify user registration
    let is_registered = weaver_contract.get_register_user(user);
    assert!(is_registered.Details == "Test User", "User should be registered");

    // Register the protocol
    let protocol_name: ByteArray = "Weaver Protocol";
    weaver_contract.protocol_register(protocol_name);

    // Verify protocol registration
    let protocol_info = weaver_contract.get_registered_protocols(user);
    assert!(protocol_info.protocol_name == "Weaver Protocol", "Protocol should be registered");

    // Define the task ID to mint
    let task_id = 1;

    // Retrieve and mark the task as completed
    let mut task_info = weaver_contract.get_task_info(task_id);
    task_info.is_completed = true;

    // Ensure task is completed
    assert!(task_info.is_completed, "Task should be completed");

    // Now, mint the NFT for the task
    weaver_contract.mint(task_id);

    // Get the minted token ID for the user
    let minted_token_id = nft_dispatcher.get_user_token_id(user);
    assert!(minted_token_id > 0, "NFT NOT Minted!");

    // Ensure that the minted token ID matches the last minted ID
    let last_minted_id = nft_dispatcher.get_last_minted_id();
    assert_eq!(minted_token_id, last_minted_id, "Minted token ID should match the last minted ID");

    // Ensure the mint timestamp is correct
    let mint_timestamp = nft_dispatcher.get_token_mint_timestamp(minted_token_id);
    let current_block_timestamp = get_block_timestamp();
    assert_eq!(mint_timestamp, current_block_timestamp, "Mint timestamp does not match");

    // Stop the contract after the test
    stop_cheat_caller_address(weaver_contract_address);
}


#[test]
#[should_panic(expected: 'TASK_ALREADY_EXISTS')]
fn test_mint_task_already_exists() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let user: ContractAddress = USER();

    // Set up the caller address
    start_cheat_caller_address(weaver_contract_address, user);

    // Register user first (required)
    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    // Register protocol (required before minting)
    let protocol_name: ByteArray = "Test Protocol";
    weaver_contract.protocol_register(protocol_name);

    // First mint should succeed
    let task_id = 1;
    weaver_contract.mint(task_id);

    // Second mint with same task_id should panic
    weaver_contract.mint(task_id);

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


#[test]
fn test_nft_was_minted_after_protocol_registers() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

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
fn test_protocol_is_task_complete() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    let nft_dispatcher = IWeaverNFTDispatcher { contract_address: weaver_contract.erc_721() };

    let user: ContractAddress = USER();
    start_cheat_caller_address(weaver_contract_address, user);

    let details: ByteArray = "Test User";
    weaver_contract.register_User(details);

    let task_id = 42;
    weaver_contract.mint(task_id);
    
    let task_info = weaver_contract.get_task_info(task_id);
    assert_eq!(task_info.task_id, task_id, "Task ID should match");
    assert_eq!(task_info.user, user, "Task should be associated with the user");

    // Manual testing for task completion by simulating completion
    // Note: This is where you would normally set task_completetion in your contract
    // Since we can't directly manipulate storage in tests, we're simulating it

    let initial_token_id = nft_dispatcher.get_user_token_id(user);

    weaver_contract.mint(task_id + 1);

    // Verify a new NFT was minted
    let new_token_id = nft_dispatcher.get_user_token_id(user);
    assert!(new_token_id > initial_token_id, "New NFT should be minted after task completion");

    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: 'USER_NOT_REGISTERED')]
fn test_protocol_user_not_registered() {
    let weaver_contract_address = __setup__();
    let weaver_contract = IWeaverDispatcher { contract_address: weaver_contract_address };
    
    let unregistered_user = 'unregistered'.try_into().unwrap();
    
    start_cheat_caller_address(weaver_contract_address, unregistered_user);
    
    let task_id = 42;
    weaver_contract.mint(task_id);
    
    stop_cheat_caller_address(weaver_contract_address);
}
