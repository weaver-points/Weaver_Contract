#[starknet::interface]
pub trait Iprotocols<TContractState> {}


#[starknet::contract]
pub mod protocols {
    use super::{Iprotocols};
    use crate::mods::protocol::protocolcomponent::ProtocolCampagin;
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path: ProtocolCampagin, storage: Protocols, event: ProtocolEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub Protocols: ProtocolCampagin::Storage,
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ProtocolEvent: ProtocolCampagin::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }


    #[abi(embed_v0)]
    impl ProtocolImpl = ProtocolCampagin::ProtocolCampaigm<ContractState>;


    #[abi(embed_v0)]
    impl ProtocolsImpl of Iprotocols<ContractState> {}
}
