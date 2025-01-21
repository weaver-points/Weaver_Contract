// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^0.16.0

#[starknet::contract]
mod erc721 {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;
    use openzeppelin::token::erc721::ERC721HooksEmptyImpl;
    use core::starknet::{ContractAddress, get_caller_address, contract_address_const};
    use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        _weaver_contract: ContractAddress, 
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.erc721.initializer("SPIDERS", "WEBS", "");
        self.ownable.initializer(owner);
        self._weaver_contract.write(contract_address_const::<0>()); // Initialize to zero
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn safe_mint(
            ref self: ContractState,
            recipient: ContractAddress,
            token_id: u256,
            data: Span<felt252>,
        ) {
            let caller = get_caller_address();
            if caller != self._weaver_contract.read() {
                self.ownable.assert_only_owner();
            }
            self.erc721.safe_mint(recipient, token_id, data);
        }

        #[external(v0)]
        fn set_weaver_contract(ref self: ContractState, weaver: ContractAddress) {
            self.ownable.assert_only_owner();
            self._weaver_contract.write(weaver);
        }
        
        #[external(v0)]
        fn get_weaver_contract(self: @ContractState) -> ContractAddress {
            self._weaver_contract.read()
        }

        #[external(v0)]
        fn safeMint(
            ref self: ContractState, recipient: ContractAddress, tokenId: u256, data: Span<felt252>,
        ) {
            self.safe_mint(recipient, tokenId, data);
        }
    }
}
