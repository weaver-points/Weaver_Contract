use starknet::ContractAddress;
use starknet::class_hash::ClassHash;

// *************************************************************************
//                              INTERFACE of  WEAVER
// *************************************************************************


use crate::mods::types::{ProtocolInfo, TaskInfo, User};

#[starknet::interface]
pub trait IWeaver<TContractState> {
    fn register_User(ref self: TContractState, Details: ByteArray);
    fn set_erc721(ref self: TContractState, address: ContractAddress);
    fn get_register_user(self: @TContractState, address: ContractAddress) -> User;
    fn version(self: @TContractState) -> u16;
    fn upgrade(ref self: TContractState, Imp_hash: ClassHash);
    fn owner(self: @TContractState) -> ContractAddress;
    fn erc_721(self: @TContractState) -> ContractAddress;
    fn mint(ref self: TContractState, task_id: u256);
    fn get_task_info(self: @TContractState, task_id: u256) -> TaskInfo;
    fn protocol_register(ref self: TContractState, protocol_name: ByteArray);
    fn get_registered_protocols(self: @TContractState, address: ContractAddress) -> ProtocolInfo;
}
