#[starknet::contract]
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
        get_caller_address,
    };

    use crate::mods::types::{ProtocolInfo, TaskInfo, User};
    use crate::mods::events::{ProtocolRegistered, TaskMinted, Upgraded, UserRegistered};
    use crate::mods::errors::Errors;
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
        registered: Map::<ContractAddress, bool>,
        // user_index: Map::<u256, ContractAddress>,
        user_count: u256,
        version: u16,
        task_registry: Map::<u256, TaskInfo>,
        protocol_registrations: Map::<ContractAddress, ProtocolInfo>,
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Copy, Drop, starknet::Event)]
    pub enum Event {
        Upgraded: Upgraded,
        UserRegistered: UserRegistered,
        ProtocolRegistered: ProtocolRegistered,
        TaskMinted: TaskMinted,
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[abi(embed_v0)]
    impl WeaverImpl of IWeaver<ContractState> {
        fn register_User(ref self: ContractState, Details: ByteArray) {
            assert(!self.registered.read(get_caller_address()), Errors::USER_ALREADY_REGISTERED);
            self.registered.write(get_caller_address(), true);
            self.users.write(get_caller_address(), User { Details });
            let total_users = self.user_count.read() + 1;
            self.user_count.write(total_users);
            let weavernft_dispatcher = IWeaverNFTDispatcher {
                contract_address: self.weaver_nft_address.read(),
            };
            weavernft_dispatcher.mint_weaver_nft(get_caller_address());
            self.emit(Event::UserRegistered(UserRegistered { user: get_caller_address() }));
        }


        fn mint(ref self: ContractState, task_id: u256) {
            let caller = get_caller_address();

            // Verify user is registered
            assert(self.registered.read(caller), Errors::USER_NOT_REGISTERED);

            // Veriy task does not exist
            assert(!self.task_registry.read(task_id).is_completed, Errors::TASK_ALREADY_EXISTS);

            let task_info = TaskInfo { task_id, user: caller, is_completed: true };
            self.task_registry.write(task_id, task_info);

            // Get NFT contract dispatcher
            let weavernft_dispatcher = IWeaverNFTDispatcher {
                contract_address: self.weaver_nft_address.read(),
            };

            // Mint NFT to user
            weavernft_dispatcher.mint_weaver_nft(caller);
            self.emit(Event::TaskMinted(TaskMinted { task_id, user: caller }));
        }


        fn protocol_register(ref self: ContractState, protocol_name: ByteArray) {
            assert(protocol_name.len() > 0, Errors::INVALID_PROTOCOL_NAME);

            let protocol_info = self.protocol_registrations.read(get_caller_address());
            assert(protocol_info.protocol_name.len() == 0, Errors::PROTOCOL_ALREADY_REGISTERED);
            self.protocol_registrations.write(get_caller_address(), ProtocolInfo { protocol_name });

            // Dispatch the mint_weaver_nft call to the NFT contract
            let weaver_nft_dispatcher = IWeaverNFTDispatcher {
                contract_address: self.weaver_nft_address.read(),
            };
            weaver_nft_dispatcher.mint_weaver_nft(get_caller_address());
            self.emit(Event::ProtocolRegistered(ProtocolRegistered { user: get_caller_address() }));
        }


        // add a verify function

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

        fn get_task_info(self: @ContractState, task_id: u256) -> TaskInfo {
            self.task_registry.read(task_id)
        }

        fn get_registered_protocols(
            self: @ContractState, address: ContractAddress,
        ) -> ProtocolInfo {
            self.protocol_registrations.read(address)
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
