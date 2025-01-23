#[starknet::contract]
pub mod WeaverNFT {
    // *************************************************************************
    //                             IMPORTS
    // *************************************************************************
    use starknet::{ContractAddress, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin::{access::ownable::OwnableComponent};

    use starknet::storage::{
        Map, StoragePointerWriteAccess, StoragePointerReadAccess, StorageMapReadAccess,
        StorageMapWriteAccess
    };
    use weaver_contract::interfaces::IWeaverNFT;

    // *************************************************************************
    //                             COMPONENTS
    // *************************************************************************
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC721 Mixin
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // *************************************************************************
    //                             STRUCTS
    // *************************************************************************
    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct TaskInfo {
        task_id: u256,
        user: ContractAddress,
        is_completed: bool,
    }

    // *************************************************************************
    //                             STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin: ContractAddress,
        last_minted_id: u256,
        mint_timestamp: Map<u256, u64>,
        user_token_id: Map<ContractAddress, u256>,
        task_registry: Map<u256, TaskInfo>,
        user_registered: Map<ContractAddress, bool>,
    }

    // *************************************************************************
    //                             EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
        self
            .erc721
            .initializer(
                "SPIDERS", "WEBS", ""  // The pinata URL will be updated soon
            );
    }


    #[abi(embed_v0)]
    impl WeaverImpl of IWeaverNFT::IWeaverNFT<ContractState> {
        // *************************************************************************
        //                            EXTERNAL
        // *************************************************************************

        fn mint_weaver_nft(ref self: ContractState, task_id: u256, address: ContractAddress) {
            // Validate address
            assert(address.is_non_zero(), 'INVALID_ADDRESS');
            
            // Check if user is registered
            assert(self.user_registered.read(address), 'USER_NOT_REGISTERED');
            
            // Get task info and validate
            let task_info = self.task_registry.read(task_id);
            assert(task_info.task_id == task_id, 'INVALID_TASK_ID');
            assert(task_info.is_completed, 'TASK_NOT_COMPLETED');
            assert(task_info.user == address, 'UNAUTHORIZED_USER');
            
            // Ensure user hasn't already minted
            let existing_token = self.user_token_id.read(address);
            assert(existing_token.is_zero(), 'ALREADY_MINTED');

            // Mint NFT
            let token_id = self.last_minted_id.read() + 1;
            self.erc721.mint(address, token_id);
            let timestamp: u64 = get_block_timestamp();

            // Update storage
            self.user_token_id.write(address, token_id);
            self.last_minted_id.write(token_id);
            self.mint_timestamp.write(token_id, timestamp);
        }


        fn get_user_token_id(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_token_id.read(user)
        }


        fn get_last_minted_id(self: @ContractState) -> u256 {
            self.last_minted_id.read()
        }


        fn get_token_mint_timestamp(self: @ContractState, token_id: u256) -> u64 {
            self.mint_timestamp.read(token_id)
        }
    }
}