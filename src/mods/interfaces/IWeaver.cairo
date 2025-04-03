use starknet::ContractAddress;
use starknet::class_hash::ClassHash;

// *************************************************************************
//                              INTERFACE of  WEAVER
// *************************************************************************

use crate::mods::types::{ProtocolInfo, TaskInfo, User};

#[starknet::interface]
pub trait IWeaver<TState> {
    fn register_User(ref self: TState, Details: ByteArray);
}
