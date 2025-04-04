use starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use crate::mods::types::CampaignMembers;
use crate::mods::types::ProtocolDetails;
use crate::mods::types::ProtocolInfo;


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
    fn protocol_register(ref self: TState, protocol_Details: ByteArray);
    fn verfify_protocol(ref self: TState, protocol_address: ContractAddress);


    // *************************************************************************
    //                            GETTER
    // *************************************************************************

    fn is_campaign_member(
        self: @TState, campaign_user: ContractAddress, protocol_id: u256
    ) -> (bool, CampaignMembers);

    fn get_protocol(self: @TState, protocol_id: u256) -> ProtocolDetails;

    fn get_protocol_matadata_uri(self: @TState, protocol_id: u256) -> ByteArray;
    fn get_protocol_campaign_users(self: @TState, protocol_id: u256) -> u256;

    fn get_campaign_members(self: @TState, protocol_id: u256) -> CampaignMembers;

    fn get_registered_protocol(self: @TState, protocol_owner: ContractAddress) -> ProtocolInfo;


    fn get_protocol_nft_class_hash(self: @TState) -> ClassHash;
}
