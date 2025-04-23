use core::byte_array::ByteArray;
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::starknet::SyscallResultTrait;
use core::starknet::syscalls::deploy_syscall;
use core::traits::TryInto;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use weaver_contract::mods::interfaces::ICustomNFT::{
    ICustomNFTDispatcher, ICustomNFTDispatcherTrait,
};
use weaver_contract::mods::interfaces::Iprotocol::{IProtocolDispatcher, IProtocolDispatcherTrait};
use weaver_contract::mods::interfaces::IWeaver::{IWeaverDispatcher, IWeaverDispatcherTrait};
use weaver_contract::mods::interfaces::IWeaverNFT::{
    IWeaverNFTDispatcher, IWeaverNFTDispatcherTrait,
};
use weaver_contract::mods::protocol::protocolcomponent::ProtocolCampaign;

use weaver_contract::mods::protocol::protocols::protocols;
use weaver_contract::mods::protocol::protocolcomponent::ProtocolCampaign::UserEventType;
use weaver_contract::mods::types::{CampaignMembers, ProtocolDetails, ProtocolInfo, User,};


fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

fn PROTOCOL() -> ContractAddress {
    'protocol'.try_into().unwrap()
}

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}


fn ___setup___() -> ContractAddress {
    // deploy protocol nft
    let protocol_nft_class_hash = declare("protocolNFT").unwrap().contract_class();

    // Deploy the protocl contract
    let protocol_contract = declare("protocols").unwrap().contract_class();

    let mut constructor_data: Array<felt252> = array![(*protocol_nft_class_hash.class_hash).into()];

    let (protocol_contract_address, _) = protocol_contract.deploy(@constructor_data).unwrap();

    return protocol_contract_address;
}


fn setup_weaver() -> ContractAddress {
    let weaver_class_hash = declare("Weaver").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    let (weaver_contract_address, _) = weaver_class_hash.deploy(@calldata).unwrap();
    let weaver_NFT = __deploy_weaver_erc721__(OWNER());
    let weaver = IWeaverDispatcher { contract_address: weaver_contract_address };

    let owner = weaver.get_owner();

    start_cheat_caller_address(weaver_contract_address, owner);
    weaver.set_erc721(weaver_NFT);
    stop_cheat_caller_address(weaver_contract_address);

    return weaver_contract_address;
}


fn __deploy_weaver_erc721__(admin: ContractAddress) -> ContractAddress {
    let weaver_erc721_class_hash = declare("WeaverNFT").unwrap().contract_class();
    let mut calldata = array![];
    admin.serialize(ref calldata);
    let (weaver_erc721_contract_address, _) = weaver_erc721_class_hash.deploy(@calldata).unwrap();

    return weaver_erc721_contract_address;
}


#[test]
fn test_protocol_registration() {
    let protocol_contract_address = ___setup___();
    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };
    let mut protocol_Details: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    //register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_Details.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    assert!(is_protocol_registered.protocol_owner == protocol, "Invalid protocol owner");
    assert!(is_protocol_registered.protocol_id == 1, "Invalid protocol id");
    assert!(is_protocol_registered.registered == true, "Invalid protocol registration");
    assert!(is_protocol_registered.verified == false, "Invalid protocol verification");
    stop_cheat_caller_address(protocol_contract_address);
}

#[test]
#[should_panic(expected: 'PROTOCOL_ALREADY_REGISTERED')]
fn test_protocol_registration_already_registered() {
    let protocol_contract_address = ___setup___();
    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };
    let mut protocol_Details: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    //register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_Details.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    //register protocol again
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_Details.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);
}


#[test]
fn test_create_protocol_campaign() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    // register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_info.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );
    stop_cheat_caller_address(protocol_contract_address);
}

#[test]
#[should_panic(expected: 'PROTOCOL_NOT_REGISTERED')]
fn test_create_protocol_campaign_by_unregistered_protocol() {
    let protocol_contract_address = ___setup___();
    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    // skip protocol registration, to check if the protocol without registration can create a
    // campaign

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );
    stop_cheat_caller_address(protocol_contract_address);
}


#[test]
fn test_join_protocol_campaign() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    // register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_info.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );

    stop_cheat_caller_address(protocol_contract_address);

    let user = USER();
    start_cheat_caller_address(protocol_contract_address, user);

    let protocol_data = protocol_dispatcher.get_protocol(id);
    protocol_dispatcher.join_protocol_campaign(user, id);
    let is_user_joined = protocol_dispatcher.get_campaign_for_member(id, user);
    assert!(is_user_joined.user_address == user, "Invalid user address");
    assert!(is_user_joined.protocol_id == id, "Invalid protocol id");

    let all_user_campaign = protocol_dispatcher.get_all_campaign_for_members(user);
    assert_eq!(all_user_campaign[0].protocol_id, @id, "Invalid protocol id");
    assert_eq!(all_user_campaign[0].user_address, @user, "Invalid user address");
    stop_cheat_caller_address(protocol_contract_address);
}


#[test]
#[should_panic(expected: 'INVALID_PROTOCOL_ID')]
fn test_join_protocol_campaign_invalid_protocol_id() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    // register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_info.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );

    stop_cheat_caller_address(protocol_contract_address);

    let user = USER();

    start_cheat_caller_address(protocol_contract_address, user);

    let user_join_campaign = protocol_dispatcher.join_protocol_campaign(user, 0);

    stop_cheat_caller_address(protocol_contract_address);
}

#[test]
#[should_panic(expected: 'INVALID_ADDRESS')]
fn test_join_protocol_campaign_with_zero_address() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();
    let zero_address = contract_address_const::<0>();

    // register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_info.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );

    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, zero_address);
    let user_join_campaign = protocol_dispatcher.join_protocol_campaign(zero_address, id);
    stop_cheat_caller_address(protocol_contract_address);
}

#[test]
#[should_panic(expected: 'UNAUTHORIZED')]
fn test_join_protocol_campaign_not_caller() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();
    let zero_address = contract_address_const::<0>();

    // register protocol
    start_cheat_caller_address(protocol_contract_address, protocol);
    protocol_dispatcher.protocol_register(protocol_info.clone());
    let is_protocol_registered = protocol_dispatcher.get_registered_protocol(protocol);
    assert!(is_protocol_registered.protocol_Details == "WEAVER", "Invalid protocol info");
    stop_cheat_caller_address(protocol_contract_address);

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111, "Invalid protocol campaign id");

    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(
        protocol_data.protocol_nft_address != contract_address_const::<0>(),
        "protocol nft address is not deployed"
    );

    stop_cheat_caller_address(protocol_contract_address);

    let user = USER();

    start_cheat_caller_address(protocol_contract_address, user);
    let user_join_campaign = protocol_dispatcher.join_protocol_campaign(protocol, id);
    stop_cheat_caller_address(protocol_contract_address);
}


#[test]
fn test_weaver_register_user() {
    let weaver_contract_address = setup_weaver();
    let weaver = IWeaverDispatcher { contract_address: weaver_contract_address };
    let user = USER();
    let user_details: ByteArray = "WEAVER";
    start_cheat_caller_address(weaver_contract_address, user);
    weaver.register_User(user_details.clone());
    let is_user_registered = weaver.get_register_user(user);
    assert!(is_user_registered.registered == true, "Invalid user registration");
    assert!(is_user_registered.user_id == 1, "Invalid user id");
    assert!(is_user_registered.user_owner == user, "Invalid user owner");
    assert!(is_user_registered.Details == "WEAVER", "Invalid user details");
    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
#[should_panic(expected: 'USER_ALREADY_REGISTERED')]
fn test_weaver_register_user_already_registered() {
    let weaver_contract_address = setup_weaver();
    let weaver = IWeaverDispatcher { contract_address: weaver_contract_address };
    let user = USER();
    let user_details: ByteArray = "WEAVER";
    start_cheat_caller_address(weaver_contract_address, user);
    weaver.register_User(user_details.clone());
    let is_user_registered = weaver.get_register_user(user);
    assert!(is_user_registered.registered == true, "Invalid user registration");
    assert!(is_user_registered.user_id == 1, "Invalid user id");
    assert!(is_user_registered.user_owner == user, "Invalid user owner");
    assert!(is_user_registered.Details == "WEAVER", "Invalid user details");
    stop_cheat_caller_address(weaver_contract_address);

    start_cheat_caller_address(weaver_contract_address, user);
    weaver.register_User(user_details.clone());
    let is_user_registered = weaver.get_register_user(user);
    assert!(is_user_registered.registered == true, "Invalid user registration");
    assert!(is_user_registered.user_id == 1, "Invalid user id");
    assert!(is_user_registered.user_owner == user, "Invalid user owner");
    assert!(is_user_registered.Details == "WEAVER", "Invalid user details");
    stop_cheat_caller_address(weaver_contract_address);
}

#[test]
fn test_set_erc721() {
    let weaver_contract_address = setup_weaver();
    let weaver = IWeaverDispatcher { contract_address: weaver_contract_address };
    let owner = weaver.get_owner();
    let weaver_erc721 = __deploy_weaver_erc721__(owner);
    start_cheat_caller_address(weaver_contract_address, owner);
    weaver.set_erc721(weaver_erc721);
    weaver.get_erc721();
    assert!(weaver.get_erc721() == weaver_erc721, "Invalid erc721 address");
    stop_cheat_caller_address(weaver_contract_address);
}

