use starknet::ContractAddress;
use crate::mods::types::CampaignMembers;

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


    fn is_task_complete(ref self: TState, campaign_user: ContractAddress, task_id: u256) -> bool;


    // *************************************************************************
    //                            GETTER
    // *************************************************************************

    fn is_campaign_member(
        self: @TState, campaign_user: ContractAddress, protocol_id: u256
    ) -> (bool, CampaignMembers);
}
