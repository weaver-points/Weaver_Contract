use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto};
use core::byte_array::ByteArray;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
};

use weaver_contract::mods::protocol::protocols::protocols;
use weaver_contract::mods::interfaces::Iprotocol::{IProtocolDispatcher, IProtocolDispatcherTrait};
use weaver_contract::mods::interfaces::ICustomNFT::{
    ICustomNFTDispatcher, ICustomNFTDispatcherTrait
};

use core::starknet::syscalls::deploy_syscall;
use core::starknet::SyscallResultTrait;


fn ___setup___() -> IProtocolDispatcher {
    let (address, _) = deploy_syscall(
        protocols::TEST_CLASS_HASH.try_into().unwrap(), 0, array![].span(), false,
    )
        .unwrap_syscall();

    IProtocolDispatcher { contract_address: address }
}


#[test]
fn test_create_protocol_campaign() {}

