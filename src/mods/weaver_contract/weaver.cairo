#[starknet::contract]
pub mod WeaverContract {
    use WeaverComponent::PrivateTrait;
    use starknet::ContractAddress;
    use crate::mods::weaver_contract::weaver_component::WeaverComponent;
    use openzeppelin_access::ownable::OwnableComponent;

    component!(path: WeaverComponent, storage: Weaver, event: WeaverEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl WeaverImpl = WeaverComponent::Weavers<ContractState>;
    impl WeaverPrivateimpl = WeaverComponent::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pub Weaver: WeaverComponent::Storage,
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        WeaverEvent: WeaverComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.Weaver._initialize(owner);
    }

    fn set_erc721(ref self: ContractState, weaver_nft_address: ContractAddress) {
        self.Weaver.set_erc721(weaver_nft_address);
    }
}
