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
