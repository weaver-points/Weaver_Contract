use core::starknet::ContractAddress;
use starknet::class_hash::ClassHash;
use core::fmt::{Debug, Formatter,};


#[starknet::interface]
pub trait IERC721EXT<TContractState> {
    fn safe_mint(
        ref self: TContractState, recipient: ContractAddress, token_id: u256, data: Span<felt252>,
    );
}

#[derive(Drop, Serde, Debug, PartialEq, starknet::Store)]
pub struct User {
    pub Details: ByteArray,
}

#[starknet::interface]
pub trait IWeaver<TContractState> {
    fn register_User(ref self: TContractState, Details: ByteArray);
    fn set_erc721(ref self: TContractState, address: ContractAddress);
    fn get_register_user(self: @TContractState, address: ContractAddress) -> User;
    fn version(self: @TContractState) -> u16;
    fn upgrade(ref self: TContractState, Imp_hash: ClassHash);
    fn owner(self: @TContractState) -> ContractAddress;
    fn erc_721(self: @TContractState) -> ContractAddress;
}


#[starknet::contract]
mod Weaver {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************

    use core::num::traits::Zero;
    use starknet::storage::StoragePointerReadAccess;
    use starknet::storage::StorageMapWriteAccess;
    use starknet::storage::StorageMapReadAccess;

    use starknet::storage::StoragePointerWriteAccess;
    use super::{User, IERC721EXTDispatcher, IERC721EXTDispatcherTrait};
    use starknet::{
        SyscallResultTrait, class_hash::ClassHash, storage::Map, ContractAddress, get_caller_address
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    pub struct Storage {
        owner: ContractAddress,
        erc721_address: ContractAddress,
        users: Map::<ContractAddress, User>,
        registered: Map::<ContractAddress, bool>,
        // user_index: Map::<u256, ContractAddress>,
        user_count: u256,
        version: u16,
    }


    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub enum Event {
        Upgraded: Upgraded,
    }


    #[derive(Copy, Drop, Debug, PartialEq, starknet::Event)]
    pub struct Upgraded {
        pub implementation: ClassHash
    }


    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, erc721_address: ContractAddress,
    ) {
        self.owner.write(owner);
        self.erc721_address.write(erc721_address);
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[abi(embed_v0)]
    impl WeaverImpl of super::IWeaver<ContractState> {
        fn register_User(ref self: ContractState, Details: ByteArray) {
            assert(!self.registered.read(get_caller_address()), 'user already registered');
            self.registered.write(get_caller_address(), true);
            self.users.write(get_caller_address(), User { Details });
            let total_users = self.user_count.read() + 1;
            self.user_count.write(total_users);
            let erc721_dispatcher = IERC721EXTDispatcher {
                contract_address: self.erc721_address.read()
            };
            erc721_dispatcher.safe_mint(get_caller_address(), total_users, [].span());
        }

        fn set_erc721(ref self: ContractState, address: ContractAddress) {
            assert(get_caller_address() == self.owner.read(), 'UNAUTHORIZED');
            assert(address.is_non_zero(), 'INVALID_ADDRESS');
            self.erc721_address.write(address);
        }

        fn get_register_user(self: @ContractState, address: ContractAddress) -> User {
            return self.users.read(address);
        }

        fn version(self: @ContractState) -> u16 {
            return self.version.read();
        }

        fn upgrade(ref self: ContractState, Imp_hash: ClassHash) {
            assert(Imp_hash.is_non_zero(), 'Clash Hasd Cannot be Zero');
            assert(get_caller_address() == self.owner.read(), 'UNAUTHORIZED');
            starknet::syscalls::replace_class_syscall(Imp_hash).unwrap_syscall();
            self.version.write(self.version.read() + 1);
            self.emit(Event::Upgraded(Upgraded { implementation: Imp_hash }));
        }

        fn owner(self: @ContractState) -> ContractAddress {
            return self.owner.read();
        }

        fn erc_721(self: @ContractState) -> ContractAddress {
            return self.erc721_address.read();
        }
    }
}
