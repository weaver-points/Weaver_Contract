use starknet::{ClassHash, ContractAddress};


#[derive(Copy, Drop, Serde)]
pub enum UserEventType {
    Register
}


#[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
pub struct Upgraded {
    #[key]
    pub implementation: ClassHash,
}

#[derive(Copy, Drop, starknet::Event)]
pub struct UserRegistered {
    #[key]
    pub user_id: u256,
    #[key]
    pub user: ContractAddress,
    #[key]
    pub event_type: UserEventType,
    pub block_timestamp: u64,
}

