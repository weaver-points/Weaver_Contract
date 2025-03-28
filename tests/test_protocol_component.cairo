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
use weaver_contract::mods::protocol::protocolcomponent::ProtocolCampagin;
use weaver_contract::mods::protocol::protocols::protocols;

fn USER() -> ContractAddress {
    'recipient'.try_into().unwrap()
}

fn PROTOCOL() -> ContractAddress {
    'protocol'.try_into().unwrap()
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

#[test]
fn test_create_protocol_campaign() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

   start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111,"Invalid protocol campaign id");
   
    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(protocol_data.protocol_nft_address != contract_address_const::<0>(),"protocol nft address is not deployed");
    stop_cheat_caller_address(protocol_contract_address);

}

#[test]
#[should_panic(expected: 'PROTOCOL_ALREADY_EXIST')]
fn test_create_protocol_campaign_already_exist() {
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

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

    start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    stop_cheat_caller_address(protocol_contract_address);
}

#[test]
fn test_emit_create_protocol_campaign(){
    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

    let mut spy = spy_events();

   start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111,"Invalid protocol campaign id");
   
    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(protocol_data.protocol_nft_address != contract_address_const::<0>(),"protocol nft address is not deployed");
    stop_cheat_caller_address(protocol_contract_address);

    spy
      .assert_emitted(
        @array![
            (
                protocol_contract_address,
                ProtocolCampagin::Event::ProtocolCampaign(
                    ProtocolCampagin::ProtocolCampaign{
                        protocol_id: id,
                        protocol_owner: protocol,
                        protocol_nft_address: protocol_data.protocol_nft_address,
                        block_timestamp: get_block_timestamp()

                    }
                )


            )
        ]
      )


}


#[test]
fn test_join_prototocl_campaign() {

    let protocol_contract_address = ___setup___();

    let protocol_dispatcher = IProtocolDispatcher { contract_address: protocol_contract_address };

    let id: u256 = 111;
    let mut protocol_info: ByteArray = "WEAVER";
    let protocol = PROTOCOL();

   start_cheat_caller_address(protocol_contract_address, protocol);
    let create_campaign = protocol_dispatcher.create_protocol_campaign(id, protocol_info.clone());
    assert!(create_campaign == 111,"Invalid protocol campaign id");
   
    let protocol_data = protocol_dispatcher.get_protocol(id);
    assert!(protocol_data.protocol_id == id, "Invalid protocol id");
    assert!(protocol_data.protocol_owner == protocol, "Invalid protocol owner");
    assert!(protocol_data.protocol_campaign_members == 0, "Invalid protocol campaign members");
    assert!(protocol_data.protocol_nft_address != contract_address_const::<0>(),"protocol nft address is not deployed");
    stop_cheat_caller_address(protocol_contract_address);

    let user = USER();

    start_cheat_caller_address(protocol_contract_address, user);
    let join_campaign = protocol_dispatcher.join_protocol_campaign(user, id);


    stop_cheat_caller_address(protocol_contract_address);

}

