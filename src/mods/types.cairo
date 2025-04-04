use starknet::ContractAddress;

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct User {
    pub Details: ByteArray,
    pub registered: bool,
    pub user_id: u256,
    pub user_owner: ContractAddress,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct TaskInfo {
    pub task_id: u256,
    pub user: ContractAddress,
    pub is_completed: bool,
}

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct ProtocolInfo {
    pub protocol_Details: ByteArray,
    pub registered: bool,
    pub verified: bool,
    pub protocol_id: u256,
    pub protocol_owner: ContractAddress,
}


#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct ProtocolDetails {
    pub protocol_id: u256,
    pub protocol_owner: ContractAddress,
    pub protocol_matadata_uri: ByteArray,
    pub protocol_nft_address: ContractAddress,
    pub protocol_campaign_members: u256,
    pub protocol_info: ByteArray,
}


#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct CampaignMembers {
    pub user_address: ContractAddress,
    pub protocol_id: u256,
    pub protocol_token_id: u256,
}

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct ProtocolCreateTask {
    pub protocol_id: u256,
    pub protocol_owner: ContractAddress,
    pub task_Description: ByteArray,
    pub task_id: u256,
}

