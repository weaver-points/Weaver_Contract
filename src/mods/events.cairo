use starknet::{ClassHash, ContractAddress};


#[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
pub struct Upgraded {
    pub implementation: ClassHash,
}

#[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
pub struct UserRegistered {
    #[key]
    pub user: ContractAddress,
}


#[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
pub struct TaskMinted {
    #[key]
    pub task_id: u256,
    #[key]
    pub user: ContractAddress,
}

