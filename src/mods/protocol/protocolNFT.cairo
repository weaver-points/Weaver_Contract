#[starknet::contract]
pub mod protocolNFT {
    // *************************************************************************
    //                             IMPORTS
    // *************************************************************************

    use openzeppelin_token::erc721::interface::IERC721Metadata;
use ERC721Component::InternalTrait;
use openzeppelin_token::erc721::interface::ERC721ABI;
    use starknet::{ContractAddress, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::UpgradeableComponent;


    use crate::mods::interfaces::ICustomNFT::ICustomNFT;
    use crate::mods::errors::Errors;
    use crate::mods::Utils::Convert_felt_to_bytearray::convert_into_byteArray;
   

    use starknet::storage::{
        Map, StoragePointerWriteAccess, StoragePointerReadAccess, StorageMapReadAccess,
        StorageMapWriteAccess
    };


    // *************************************************************************
    //                             COMPONENTS
    // *************************************************************************
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // ERC721 Mixin
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

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
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        last_minted_id: u256,
        mint_timestamp: Map<u256, u64>,
        user_token_id: Map<ContractAddress, u256>,
        protocol_id: u256
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
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }

    // *************************************************************************
    //                             CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, protocol_id: u256, admin: ContractAddress) {
        self.ownable.initializer(admin);
        self.protocol_id.write(protocol_id);
    }


    #[abi(embed_v0)]
    impl IprotocolNFT of ICustomNFT<ContractState> {
        fn mint_nft(ref self: ContractState, user_address: ContractAddress) -> u256 {
            let balance = self.erc721.balance_of(user_address);
            assert(balance.is_zero(), Errors::ALREADY_MINTED);
            let token_id = self.last_minted_id.read() + 1;
            self.erc721.mint(user_address, token_id);
            let timestamp: u64 = get_block_timestamp();
            self.user_token_id.write(user_address, token_id);
            self.last_minted_id.write(token_id);
            self.mint_timestamp.write(token_id, timestamp);
            return token_id;
        }


        fn burn_nft(ref self: ContractState, user_address: ContractAddress, token_id: u256) {
            let user_token_id = self.user_token_id.read(user_address);
            assert(user_token_id == token_id, Errors::INVALID_TOKEN_ID);
            assert(self.erc721.exists(token_id), Errors::TOKEN_NOT_EXISTS);
            self.erc721.burn(token_id);
            self.user_token_id.write(user_address, 0);
        }


        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        fn get_user_token_id(self: @ContractState, user: ContractAddress) -> u256 {
            return self.user_token_id.read(user);
        }


        // *************************************************************************
        //                            METADATA
        // *************************************************************************


        fn name(self: @ContractState) -> ByteArray {
            let mut collection_name = ArrayTrait::<felt252>::new();
            let protocol_id_felt252: felt252 = self.protocol_id.read().try_into().unwrap();
            collection_name.append('PROTOCOL');
            collection_name.append(protocol_id_felt252);
            let protocol_name_byte =  convert_into_byteArray(ref collection_name);

            return protocol_name_byte;
          
        }


        fn symbol(self: @ContractState)-> ByteArray {
            return "";
        }


         fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            let token_uri = IERC721Metadata::token_uri(self.erc721, token_id);
            return token_uri;
         }
    }
}



 
