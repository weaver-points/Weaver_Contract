use starknet::ContractAddress;
use starknet::class_hash::ClassHash;

// *************************************************************************
//                              INTERFACE of  WEAVER
// *************************************************************************

use crate::mods::types::{User};

#[starknet::interface]
pub trait IWeaver<TContractState> {
    fn register_User(ref self: TContractState, Details: ByteArray);

    fn get_register_user(self: @TContractState, address: ContractAddress) -> User;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn set_erc721(ref self: TContractState, address: ContractAddress);
    fn get_user_id(self: @TContractState) -> u256;
    fn get_erc721(self: @TContractState) -> ContractAddress;
}
