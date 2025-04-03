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

    use starknet::{
        SyscallResultTrait, class_hash::ClassHash, storage::Map, ContractAddress,
        get_caller_address, get_block_timestamp
    };

    use crate::mods::types::{ProtocolInfo, TaskInfo, User};
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
        owner: ContractAddress,
        weaver_nft_address: ContractAddress,
        users: Map::<ContractAddress, User>,
        // user_index: Map::<u256, ContractAddress>,
        user_count: u256,
        User_id: u256,
        version: u16,
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
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[abi(embed_v0)]
    impl WeaverImpl of IWeaver<ContractState> {
        fn register_User(ref self: ContractState, Details: ByteArray) {
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


        // Getter functions

        fn owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }

        fn erc_721(self: @ContractState) -> ContractAddress {
            return self.weaver_nft_address.read();
        }

        fn get_register_user(self: @ContractState, address: ContractAddress) -> User {
            return self.users.read(address);
        }


        //Utility functions

        fn version(self: @ContractState) -> u16 {
            return self.version.read();
        }

        fn upgrade(ref self: ContractState, Imp_hash: ClassHash) {
            assert(Imp_hash.is_non_zero(), Errors::CLASS_HASH_CANNOT_BE_ZERO);
            assert(get_caller_address() == self.owner.read(), Errors::UNAUTHORIZED);
            starknet::syscalls::replace_class_syscall(Imp_hash).unwrap_syscall();
            self.version.write(self.version.read() + 1);
            self.emit(Event::Upgraded(Upgraded { implementation: Imp_hash }));
        }


        fn set_erc721(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), Errors::UNAUTHORIZED);
            assert(address.is_non_zero(), Errors::INVALID_ADDRESS);
            self.weaver_nft_address.write(address);
        }
    }
}
