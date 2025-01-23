use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use core::fmt::{Debug, Formatter};

// *************************************************************************
//                              INTERFACE of  WEAVER
// *************************************************************************


#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct User {
    pub Details: ByteArray,
}

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
}