use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto};
use core::byte_array::ByteArray;

use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};


use weaver_contract::mods::protocol::protocolcomponent::ProtocolCampagin;
use weaver_contract::mods::protocol::protocols::protocols;
use weaver_contract::mods::interfaces::Iprotocol::{IProtocolDispatcher, IProtocolDispatcherTrait};
use weaver_contract::mods::interfaces::ICustomNFT::{
    ICustomNFTDispatcher, ICustomNFTDispatcherTrait
};

use core::starknet::syscalls::deploy_syscall;
use core::starknet::SyscallResultTrait;


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
}

