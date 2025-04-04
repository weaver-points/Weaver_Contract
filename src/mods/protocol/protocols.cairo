#[starknet::contract]
pub mod protocols {
    use starknet::ContractAddress;
    use crate::mods::protocol::protocolcomponent::ProtocolCampagin;
    use crate::mods::weaver_contract::weaver_component::Weaver;
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path: ProtocolCampagin, storage: Protocols, event: ProtocolEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: Weaver, storage: weaver, event: WeaverEvent);


    #[abi(embed_v0)]
    impl ProtocolImpl = ProtocolCampagin::ProtocolCampaigm<ContractState>;
    impl protocolPrivateimpl = ProtocolCampagin::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub Protocols: ProtocolCampagin::Storage,
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        pub weaver: Weaver::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ProtocolEvent: ProtocolCampagin::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        WeaverEvent: Weaver::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState, protocol_nft_classhash: felt252,) {
        self.Protocols._initialize(protocol_nft_classhash);
    }
}

