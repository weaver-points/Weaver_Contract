#[starknet::component]
pub mod ProtocolCampagin {
    use core::traits::TryInto;
    use core::num::traits::zero::Zero;

    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };


    use openzeppelin_access::ownable::OwnableComponent;

    use crate::mods::interfaces::Iprotocol::IProtocol;
    use crate::mods::interfaces::ICustomNFT::{ICustomNFTDispatcher, ICustomNFTDispatcherTrait};
    use crate::mods::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};

    use crate::mods::errors::Errors;
    use crate::mods::types::ProtocolDetails;
    use crate::mods::types::CampaignMembers;


    #[storage]
    pub struct Storage {
        protocol_id: u256,
        protocol_counter: u256,
        protocol_nft_class_hash: ClassHash, //  The protocol nft class hash 
        protocol_owner: Map<u256, ContractAddress>, // map the owner address and the protocol id 
        protocols: Map<u256, ProtocolDetails>, // map the protocol details and the protocol id 
        protocol_initialized: Map<u256, bool>, // track if the protocol id has been used or not 
        users_count: u256,
        Campaign_members: Map<
            (u256, ContractAddress), CampaignMembers
        >, // map the protocol id and the users interested on the protocol campaign
        protocol_task_description: Map<u256, ByteArray>
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
        /// @notice Create a new protocol campaign

        fn create_protocol_campaign(
            ref self: ComponentState<TContractState>, protocol_id: u256
        ) -> u256 {
            // Get the caller as the protocol owner by using the get_caller_address()

            // Read from state the protocol_nft_class_hash

            // Check if the protocol_id exist by reading from state i.e protocol_initialized
            // and also assert if it exist  Errors::PROTOCOL_ALREADY_EXIST

            // deploy protocol nft by calling the internal function _deploy_protocol_nft()

            // Create a protocol nft by calling the internal function _protocol_campaign()

            return protocol_id;
        }


        /// @notice adds users to the protocol campaign
        /// campaign_user: The user that joins the protocol campaign
        /// protocol_id: The id of the protocol that the user will join their campaign

        fn join_protocol_campaign(
            ref self: ComponentState<TContractState>,
            campaign_user: ContractAddress,
            protocol_id: u256
        ) {
        // check if the user is not address zero

        // Get the caller as the campaign user by using the get_caller_address()

        // read from state if the protocols exists

        // check if the user is not already on the protocol campaign by using the getter function
        // is_campaign_member()
        // and also assert with Errors::ALREADY_IN_PROTOCOL_CAMPAIGN

        //join the campaign by calling the internal function _join_protocol_campaign()

        }


        /// @notice set the matadat uri of the protocol
        /// protcol_id: the protocol_id for the protocol
        /// matadata_uri: The protocol matadata uri

        fn set_protocol_matadata_uri(
            ref self: ComponentState<TContractState>, protocol_id: u256, matadata_uri: ByteArray
        ) {
            let protocol_owner = self.protocol_owner.read(protocol_id);
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

        fn _protocol_campaign(
            ref self: ComponentState<TContractState>,
            protocol_owner: ContractAddress,
            protocol_nft_address: ContractAddress,
            protocol_id: u256,
            protocol_task_description: ByteArray
        ) {
            // write to storage

            let protocol_details = ProtocolDetails {
                protocol_id: protocol_id,
                protocol_owner: protocol_owner,
                protocol_matadata_uri: "",
                protocol_nft_address: protocol_nft_address,
                protocol_campaign_members: 0,
                protocol_task_description: "",
            };

            self.protocols.write(protocol_id, protocol_details);
            self.protocol_initialized.write(protocol_id, true);
            self.protocol_owner.write(protocol_id, protocol_owner);
            self.protocol_counter.write(protocol_id);
            self.protocol_task_description.write(protocol_id, protocol_task_description);

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
                user_address: user, protocol_id: protocol_id, protocol_token_id: minted_token_id,
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
