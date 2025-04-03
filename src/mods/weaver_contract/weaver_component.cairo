#[starknet::component]
pub mod Weaver {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************

    use core::num::traits::Zero;
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StorageMapWriteAccess;
    use starknet::storage::StorageMapReadAccess;

    use starknet::storage::StoragePointerWriteAccess;

    use openzeppelin_access::ownable::OwnableComponent;

    use starknet::{
        SyscallResultTrait, class_hash::ClassHash, storage::Map, ContractAddress,
        get_caller_address, get_block_timestamp
    };

    use crate::mods::types::{User};
    use crate::mods::events::{TaskMinted, Upgraded, UserRegistered, UserEventType};
    use crate::mods::errors::Errors;
    use crate::mods::events;
    use crate::mods::interfaces::IWeaver::IWeaver;
    use crate::mods::interfaces::IWeaverNFT::{IWeaverNFTDispatcher, IWeaverNFTDispatcherTrait};


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    pub struct Storage {
        weaver_nft_address: ContractAddress,
        users: Map::<ContractAddress, User>,
        // user_index: Map::<u256, ContractAddress>,
        user_count: u256,
        User_id: u256,
        user: Map::<u256, ContractAddress>,
    }


    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    pub enum Event {
        Upgraded: Upgraded,
        UserRegistered: UserRegistered,
        TaskMinted: TaskMinted,
    }


    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************

    #[embeddable_as(Weaver)]
    impl WeaverImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of IWeaver<ComponentState<TContractState>> {
        fn register_User(ref self: ComponentState<TContractState>, Details: ByteArray) {
            let caller = get_caller_address();
            assert(!self.users.read(caller).registered, Errors::USER_ALREADY_REGISTERED);
            let id = self.user_count.read() + 1;
            let user = User {
                Details: Details, registered: true, user_id: id, user_owner: caller,
            };
            self.users.write(caller, user);
            self.user.write(id, caller);
            self.user_count.write(id);

            let weavernft_dispatcher = IWeaverNFTDispatcher {
                contract_address: self.weaver_nft_address.read(),
            };
            weavernft_dispatcher.mint_weaver_nft(caller);

            self
                .emit(
                    Event::UserRegistered(
                        events::UserRegistered {
                            user_id: id,
                            user: caller,
                            event_type: UserEventType::Register,
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                );
        }
    }
}
