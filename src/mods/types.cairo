use starknet::ContractAddress;

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct User {
    pub Details: ByteArray,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct TaskInfo {
    pub task_id: u256,
    pub user: ContractAddress,
    pub is_completed: bool,
}

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct ProtocolInfo {
    pub protocol_name: ByteArray,
}


#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct ProtocolDetails {
    pub protocol_id: u256,
    pub protocol_owner: ContractAddress,
    pub protocol_matadata_uri: ByteArray,
    pub protocol_nft_address: ContractAddress,
    pub protocol_campaign_members: u256,
}


#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct CampaignMembers {
    pub user_address: ContractAddress,
    pub protocol_id: u256,
    pub protocol_token_id: u256,
}
