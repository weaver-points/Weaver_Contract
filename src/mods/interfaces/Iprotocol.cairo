use starknet::ContractAddress;
use crate::mods::types::CampaignMembers;
use crate::mods::types::ProtocolDetails;
use crate::mods::types::ProtocolCreateTask;

#[starknet::interface]
pub trait IProtocol<TState> {
    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************

    fn create_protocol_campaign(
        ref self: TState, protocol_id: u256, protocol_info: ByteArray
    ) -> u256;
    fn join_protocol_campaign(ref self: TState, campaign_user: ContractAddress, protocol_id: u256);
    fn set_protocol_matadata_uri(ref self: TState, protocol_id: u256, matadata_uri: ByteArray);
    fn create_task(ref self: TState, task_description: ByteArray) -> u256;
    fn protocol_register(ref self: TState, protocol_Details: ByteArray);


    // *************************************************************************
    //                            GETTER
    // *************************************************************************

    fn is_task_complete(ref self: TState, campaign_user: ContractAddress, task_id: u256) -> bool;
    fn mark_task_complete(ref self: TState, campaign_user: ContractAddress, task_id: u256);
    fn is_campaign_member(
        self: @TState, campaign_user: ContractAddress, protocol_id: u256
    ) -> (bool, CampaignMembers);

    fn get_protocol(self: @TState, protocol_id: u256) -> ProtocolDetails;

    fn get_protocol_matadata_uri(self: @TState, protocol_id: u256) -> ByteArray;

    fn get_protocol_tasks_details(self: @TState, protocol_id: u256) -> ProtocolCreateTask;

    fn get_protocol_task_descriptions(self: @TState, task_id: u256) -> ByteArray;

    fn get_protocol_campaign_users(self: @TState, protocol_id: u256) -> u256;

    fn get_campaign_members(self: @TState, protocol_id: u256) -> CampaignMembers;
}
