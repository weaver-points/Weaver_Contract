#[starknet::component]
pub mod ProtocolCampaign {
    use core::traits::TryInto;
    use core::num::traits::zero::Zero;

    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };


    use openzeppelin_access::ownable::OwnableComponent;

    use crate::mods::interfaces::Iprotocol::IProtocol;
    use crate::mods::interfaces::ICustomNFT::{ICustomNFTDispatcher, ICustomNFTDispatcherTrait};

    use crate::mods::errors::Errors;
    use crate::mods::types::ProtocolDetails;
    use crate::mods::types::CampaignMembers;
    use crate::mods::types::ProtocolInfo;
    use crate::mods::types::User;


    #[storage]
    pub struct Storage {
        pub protocol_id: u256,
        pub protocol_counter: u256,
        pub protocol_nft_class_hash: ClassHash, //  The protocol nft class hash 
        protocol_owner: Map::<u256, ContractAddress>, // map the owner address and the protocol id 
        protocols: Map::<u256, ProtocolDetails>, // map the protocol details and the protocol id 
        users_count: u256,
        pub Campaign_members: Map::<
            (u256, ContractAddress), CampaignMembers
        >, // map the protocol id and the users interested on the protocol campaign
        protocol_info: Map::<u256, ByteArray>, // map the protocol id to the protocol details 
        pub protocol_register: Map::<
            ContractAddress, ProtocolInfo
        >, // map the protocol owner to the protocol info
    }


    // *************************************************************************
    //                            EVENT
    // *************************************************************************

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProtocolCampaign: ProtocolCampaign,
        JoinProtocolCampaign: JoinProtocolCampaign,
        DeployProtocolNft: DeployProtocolNft,
        ProtocolRegistered: ProtocolRegistered,
    }


    #[derive(Drop, starknet::Event)]
    pub struct ProtocolCampaign {
        pub protocol_id: u256,
        pub protocol_owner: ContractAddress,
        pub protocol_nft_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoinProtocolCampaign {
        pub protocol_id: u256,
        pub caller: ContractAddress,
        pub token_id: u256,
        pub user: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DeployProtocolNft {
        pub protocol_id: u256,
        pub protocol_nft: ContractAddress,
        pub block_timestamp: u64,
    }


    #[derive(Copy, Drop, Serde)]
    pub enum UserEventType {
        Register,
        Verify
    }


    #[derive(Drop, starknet::Event)]
    pub struct ProtocolRegistered {
        pub protocol_id: u256,
        pub protocol_owner: ContractAddress,
        pub event_type: UserEventType,
        pub block_timestamp: u64,
    }


    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************

    #[embeddable_as(ProtocolCampaigm)]
    impl ProtocolImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of IProtocol<ComponentState<TContractState>> {
        ///@ protocol registeration

        fn protocol_register(
            ref self: ComponentState<TContractState>, protocol_Details: ByteArray
        ) {
            let caller = get_caller_address();
            assert(
                !self.protocol_register.read(caller).registered, Errors::PROTOCOL_ALREADY_REGISTERED
            );
            let protocol_id = self.protocol_id.read() + 1;
            let protocol_info = ProtocolInfo {
                protocol_Details: protocol_Details,
                registered: true,
                verified: false,
                protocol_id: protocol_id,
                protocol_owner: caller,
            };

            self.protocol_register.write(caller, protocol_info);
            self.protocol_owner.write(protocol_id, caller);
            self.protocol_counter.write(protocol_id);

            self
                .emit(
                    ProtocolRegistered {
                        protocol_id: protocol_id,
                        protocol_owner: caller,
                        event_type: UserEventType::Register,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }


        /// @notice Create a new protocol campaign
        fn create_protocol_campaign(
            ref self: ComponentState<TContractState>, protocol_id: u256, protocol_info: ByteArray
        ) -> u256 {
            assert(protocol_id.is_non_zero(), Errors::INVALID_PROTOCOL_ID);
            let protocol_owner = get_caller_address();
            assert(
                self.protocol_register.read(protocol_owner).registered,
                Errors::PROTOCOL_NOT_REGISTERED
            );
            let protocol_nft_class_hash = self.protocol_nft_class_hash.read();

            let protocol_nft_address = self
                ._deploy_protocol_nft(
                    protocol_owner,
                    protocol_id,
                    protocol_nft_class_hash,
                    get_block_timestamp().try_into().unwrap()
                );

            self
                ._protocol_campaign(
                    protocol_owner, protocol_nft_address, protocol_id, protocol_info
                );

            return protocol_id;
        }


        /// @notice adds users to the protocol campaign and the users needs to register first before
        /// joining the campaign and have access to weaver NFT campaign_user: The user that joins
        /// the protocol campaign protocol_id: The id of the protocol that the user will join their
        /// campaign

        fn join_protocol_campaign(
            ref self: ComponentState<TContractState>,
            campaign_user: ContractAddress,
            protocol_id: u256
        ) {
            assert(protocol_id.is_non_zero(), Errors::INVALID_PROTOCOL_ID);
            assert(!campaign_user.is_zero(), Errors::INVALID_ADDRESS);
            let caller = get_caller_address();
            assert(caller == campaign_user, Errors::UNAUTHORIZED);

            let (is_member, _): (bool, CampaignMembers) = self
                .is_campaign_member(campaign_user, protocol_id);

            assert(!is_member, Errors::ALREADY_IN_PROTOCOL_CAMPAIGN);
            let protocol_details = self.protocols.read(protocol_id);
            let protocol_nft_address = protocol_details.protocol_nft_address;

            self._join_protocol_campaign(campaign_user, protocol_nft_address, protocol_id);
        }


        /// @notice set the matadata uri of the protocol
        /// protcol_id: the protocol_id for the protocol
        /// matadata_uri: The protocol matadata uri

        fn set_protocol_matadata_uri(
            ref self: ComponentState<TContractState>, protocol_id: u256, matadata_uri: ByteArray
        ) {
            let protocol_owner = self.protocol_owner.read(protocol_id);
            assert(
                self.protocol_register.read(protocol_owner).registered,
                Errors::PROTOCOL_NOT_REGISTERED
            );
            assert(protocol_owner == get_caller_address(), Errors::UNAUTHORIZED);

            let protocol_details = self.protocols.read(protocol_id);

            let update_protocol_details = ProtocolDetails {
                protocol_matadata_uri: matadata_uri, ..protocol_details
            };

            self.protocols.write(protocol_id, update_protocol_details);
        }


        // *************************************************************************
        //                              GETTERS
        // *************************************************************************

        fn is_campaign_member(
            self: @ComponentState<TContractState>, campaign_user: ContractAddress, protocol_id: u256
        ) -> (bool, CampaignMembers) {
            let campaign_member = self.Campaign_members.read((protocol_id, campaign_user));
            if (campaign_member.protocol_id == protocol_id) {
                (true, campaign_member)
            } else {
                (false, campaign_member)
            }
        }


        /// @notice get the particular protocol details
        /// protocol_id: id of the returned community
        /// @return protocolDetails: The details of the protocol

        fn get_protocol(
            self: @ComponentState<TContractState>, protocol_id: u256
        ) -> ProtocolDetails {
            let protocol = self.protocols.read(protocol_id);
            let protocol_construct = ProtocolDetails {
                protocol_details: Option::Some(
                    self.get_registered_protocol(protocol.protocol_owner)
                ),
                ..protocol
            };
            return protocol_construct;
        }


        /// @notice get the particular protocol campaign for each users
        /// protocol_id: id of the returned community
        /// user: The user that joined the protocol campaign
        /// @return campaignMembers: The details of the protocol campaign for each users

        fn get_campaign_for_member(
            self: @ComponentState<TContractState>, protocol_id: u256, user: ContractAddress
        ) -> CampaignMembers {
            let protocol = self.protocols.read(protocol_id);
            let campaign_members = self.Campaign_members.read((protocol_id, user));
            let campaign_construct = CampaignMembers {
                campaign_details: Option::Some(self.get_protocol(protocol.protocol_id)),
                ..campaign_members
            };
            return campaign_construct;
        }


        /// @notice get the particular protocol matadata uri
        /// protocol_id: id of the returned community
        /// @return ByteArray metadata uri

        fn get_protocol_matadata_uri(
            self: @ComponentState<TContractState>, protocol_id: u256
        ) -> ByteArray {
            let protocol = self.protocols.read(protocol_id);
            return protocol.protocol_matadata_uri;
        }


        fn get_protocol_campaign_users(
            self: @ComponentState<TContractState>, protocol_id: u256
        ) -> u256 {
            let protocol = self.protocols.read(protocol_id);
            return protocol.protocol_campaign_members;
        }


        fn get_registered_protocol(
            self: @ComponentState<TContractState>, protocol_owner: ContractAddress
        ) -> ProtocolInfo {
            let protocol_info = self.protocol_register.read(protocol_owner);
            assert(protocol_info.registered, Errors::PROTOCOL_NOT_REGISTERED);
            return protocol_info;
        }


        fn get_protocol_nft_class_hash(self: @ComponentState<TContractState>) -> ClassHash {
            return self.protocol_nft_class_hash.read();
        }

        fn get_all_protocol_details(
            self: @ComponentState<TContractState>
        ) -> Array<ProtocolDetails> {
            let mut index = 1;
            let mut protocol = array![];
            let protocol_counter = self.protocol_counter.read();
            while index <= protocol_counter {
                let protocol_details = self.protocols.read(index);
                let protocol_construct = ProtocolDetails {
                    protocol_details: Option::Some(
                        self.get_registered_protocol(protocol_details.protocol_owner)
                    ),
                    ..protocol_details
                };
                protocol.append(protocol_construct);
                index += 1;
            };
            return protocol;
        }

        fn get_all_campaign_for_members(
            self: @ComponentState<TContractState>, user: ContractAddress
        ) -> Array<CampaignMembers> {
            let mut index = 1;
            let mut campaign_user = array![];
            let length = self.protocol_counter.read();
            while index <= length {
                let campaign_details = self.Campaign_members.read((index, user));
                if campaign_details.user_address == user {
                    let campaign_construct = CampaignMembers {
                        campaign_details: Option::Some(
                            self.get_protocol(campaign_details.protocol_id)
                        ),
                        ..campaign_details
                    };

                    campaign_user.append(campaign_construct);
                }

                index += 1;
            };
            return campaign_user;
        }
    }


    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************

    #[generate_trait]
    pub impl Private<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        // @notice initialize protocol component
        // protocol_nft_class_hash: classhash of protocol nft

        fn _initialize(ref self: ComponentState<TContractState>, protocol_nft_class_hash: felt252) {
            self.protocol_counter.write(0);
            self.protocol_nft_class_hash.write(protocol_nft_class_hash.try_into().unwrap());
        }


        // @notice create protocol campaign
        // Protocol_owner: The owner of the protocol
        // Protocol_nft_address: The address of the protocol nft address
        // Protocol_id: The id for the protocol
        // protocol_info: The details about the campaign

        fn _protocol_campaign(
            ref self: ComponentState<TContractState>,
            protocol_owner: ContractAddress,
            protocol_nft_address: ContractAddress,
            protocol_id: u256,
            protocol_info: ByteArray
        ) {
            // write to storage

            let protocol_details = ProtocolDetails {
                protocol_id: protocol_id,
                protocol_owner: protocol_owner,
                protocol_matadata_uri: "",
                protocol_details: Option::None,
                protocol_nft_address: protocol_nft_address,
                protocol_campaign_members: 0,
                protocol_info: "",
            };

            self.protocols.write(protocol_id, protocol_details);
            self.protocol_owner.write(key: protocol_id, value: protocol_owner);
            self.protocol_counter.write(protocol_id);
            self.protocol_info.write(protocol_id, protocol_info);

            // emit event after creating protocol creates campaign

            self
                .emit(
                    ProtocolCampaign {
                        protocol_id: protocol_id,
                        protocol_owner: protocol_owner,
                        protocol_nft_address: protocol_nft_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }


        //@notice users to join campaigns
        // user: The new user to join the campaign
        //protocol_nft_address: The address of the nft
        //protocol_id: The protocol_id the new user joined

        fn _join_protocol_campaign(
            ref self: ComponentState<TContractState>,
            user: ContractAddress,
            protocol_nft_address: ContractAddress,
            protocol_id: u256
        ) {
            // mint protocol nft to the new user joining the campaign
            let minted_token_id = self._mint_protocol_nft(user, protocol_nft_address);

            let Campaign_members = CampaignMembers {
                user_address: user,
                protocol_id: protocol_id,
                campaign_details: Option::None,
                protocol_token_id: minted_token_id,
            };

            // Update storage
            self.Campaign_members.write((protocol_id, user), Campaign_members);

            let protocol = self.protocols.read(protocol_id);
            let protocol_campaign_members = protocol.protocol_campaign_members + 1;

            // update the protocol details
            let update_protocol_details = ProtocolDetails {
                protocol_campaign_members: protocol_campaign_members, ..protocol
            };

            // update states
            self.protocols.write(protocol_id, update_protocol_details);

            self
                .emit(
                    JoinProtocolCampaign {
                        protocol_id: protocol_id,
                        caller: user,
                        token_id: minted_token_id,
                        user: user,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }


        //@notice internal function that deploys protocol nft
        //protocol_id: The id for the protocol
        //SALT: for randomization

        fn _deploy_protocol_nft(
            ref self: ComponentState<TContractState>,
            protocol_owner: ContractAddress,
            protocol_id: u256,
            protocol_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            let mut constructor_data: Array<felt252> = array![
                protocol_id.low.into(), protocol_id.high.into(), protocol_owner.into()
            ];

            let (account_address, _) = deploy_syscall(
                protocol_nft_impl_class_hash, salt, constructor_data.span(), true
            )
                .unwrap_syscall();

            self
                .emit(
                    DeployProtocolNft {
                        protocol_id: protocol_id,
                        protocol_nft: account_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
            return account_address;
        }


        //@notice mint protocol nft to users who wants to participate on protocol campaign
        // user: user to mint to
        //protocol_nft_address: Address of the protocol nft

        fn _mint_protocol_nft(
            ref self: ComponentState<TContractState>,
            user: ContractAddress,
            protocol_nft_address: ContractAddress
        ) -> u256 {
            let token_id = ICustomNFTDispatcher { contract_address: protocol_nft_address }
                .mint_nft(user);

            return token_id;
        }
    }
}

