#[starknet::contract]
pub mod protocols {
    use starknet::ContractAddress;
    use crate::mods::protocol::protocolcomponent::ProtocolCampaign;
    // use crate::mods::weaver_contract::weaver_component::WeaverComponent;
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path: ProtocolCampaign, storage: Protocols, event: ProtocolEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);


    #[abi(embed_v0)]
    impl ProtocolImpl = ProtocolCampaign::ProtocolCampaigm<ContractState>;
    impl protocolPrivateimpl = ProtocolCampaign::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub Protocols: ProtocolCampaign::Storage,
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ProtocolEvent: ProtocolCampaign::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState, protocol_nft_classhash: felt252) {
        self.Protocols._initialize(protocol_nft_classhash);
    }
}

