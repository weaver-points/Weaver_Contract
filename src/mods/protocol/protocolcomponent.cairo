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
    use crate::mods::types::ProtocolCreateTask;


    #[storage]
    pub struct Storage {
        pub protocol_id: u256,
        protocol_counter: u256,
        pub protocol_nft_class_hash: ClassHash, //  The protocol nft class hash 
        protocol_owner: Map<u256, ContractAddress>, // map the owner address and the protocol id 
        protocols: Map<u256, ProtocolDetails>, // map the protocol details and the protocol id 
        protocol_initialized: Map<u256, bool>, // track if the protocol id has been used or not 
        users_count: u256,
        pub Campaign_members: Map<
            (u256, ContractAddress), CampaignMembers
        >, // map the protocol id and the users interested on the protocol campaign
        protocol_info: Map<u256, ByteArray>, // map the protocol id to the protocol details 
        protocol_tasks: Map<
            u256, ProtocolCreateTask
        >, // map the protocol create task to the task_id
        pub protocol_task_id: u256,
        protocol_task_descriptions: Map<
            (u256, u256), ByteArray
        >, // map the task description to the protocol_id and to the task_id
        pub tasks: Map<
            (u256, ContractAddress), u256
        >, // map the protocol_id and the protocol_owner to the task_id
        tasks_initialized: Map<u256, bool>, // track if the task_id has been used or not
        task_counter: u256,
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
        CreateTask: CreateTask,
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


    #[derive(Drop, starknet::Event)]
    pub struct CreateTask {
        pub protocol_id: u256,
        pub task_id: u256,
        pub protocol_owner: ContractAddress,
        pub task_description: ByteArray,
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
            ref self: ComponentState<TContractState>, protocol_id: u256, protocol_info: ByteArray
        ) -> u256 {
            let protocol_owner = get_caller_address();
            let protocol_nft_class_hash = self.protocol_nft_class_hash.read();
            let protocol_initialized = self.protocol_initialized.read(protocol_id);
            assert(!protocol_initialized, Errors::PROTOCOL_ALREADY_EXIST);

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


        /// @notice adds users to the protocol campaign
        /// campaign_user: The user that joins the protocol campaign
        /// protocol_id: The id of the protocol that the user will join their campaign

        fn join_protocol_campaign(
            ref self: ComponentState<TContractState>,
            campaign_user: ContractAddress,
            protocol_id: u256
        ) {
            assert(!campaign_user.is_zero(), Errors::INVALID_ADDRESS);
            let caller = get_caller_address();
            assert(caller == campaign_user, Errors::UNAUTHORIZED);

            let protocol_initialized = self.protocol_initialized.read(protocol_id);
            assert(protocol_initialized, Errors::PROTOCOL_DOES_NOT_EXIST);

            let (is_member, _): (bool, CampaignMembers) = self
                .is_campaign_member(campaign_user, protocol_id);

            assert(!is_member, Errors::ALREADY_IN_PROTOCOL_CAMPAIGN);
            let protocol_details = self.protocols.read(protocol_id);
            let protocol_nft_address = protocol_details.protocol_nft_address;

            self._join_protocol_campaign(campaign_user, protocol_nft_address, protocol_id);
        }


        fn create_task(
            ref self: ComponentState<TContractState>, task_description: ByteArray
        ) -> u256 {
            let protocol_owner = get_caller_address();

            let task_id = self.protocol_task_id.read() + 1;

            let task_exists = self.tasks_initialized.read(task_id);
            assert(!task_exists, Errors::TASK_ALREADY_EXIST);

            let protocol_id = self.protocol_id.read();
            let protocol_owner_stored = self.protocol_owner.read(protocol_id);
            assert(protocol_owner == protocol_owner_stored, Errors::UNAUTHORIZED);

            self._create_task(protocol_id, task_id, task_description, protocol_owner);

            return task_id;
        }


        fn is_task_complete(
            ref self: ComponentState<TContractState>, campaign_user: ContractAddress, task_id: u256
        ) -> bool {
            // check if the user joined the campaign

            // check if the task has been completed
            //  assert if the task has not yet been completed Errors::TASK_NOT_YET_COMPLETED

            // mint the protocol nft to the user that completed the task by calling the
            // _mint_protocol_nft()

            return true;
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
                protocol_nft_address: protocol_nft_address,
                protocol_campaign_members: 0,
                protocol_info: "",
            };

            self.protocols.write(protocol_id, protocol_details);
            self.protocol_initialized.write(protocol_id, true);
            self.protocol_owner.write(protocol_id, protocol_owner);
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

        ///@notice internal function that create task for the protocol
        /// protocol_id: The id of the protocol that created the task
        /// task_id: The task id of the task that was created
        /// task_description: The description of the task
        /// protocol_owner: The owner of the task created

        fn _create_task(
            ref self: ComponentState<TContractState>,
            protocol_id: u256,
            task_id: u256,
            task_description: ByteArray,
            protocol_owner: ContractAddress
        ) {
            // write to the storage

            let task_descriptions = ProtocolCreateTask {
                protocol_id: protocol_id,
                protocol_owner: protocol_owner,
                task_id: task_id,
                task_Description: task_description.clone()
            };

            self.protocol_tasks.write(task_id, task_descriptions);
            self.protocol_task_id.write(task_id);
            self.tasks.write((protocol_id, protocol_owner), task_id);
            self.protocol_task_descriptions.write((protocol_id, task_id), task_description.clone());
            self.tasks_initialized.write(task_id, true);
            self.task_counter.write(task_id);

            self
                .emit(
                    CreateTask {
                        protocol_id: protocol_id,
                        task_id: task_id,
                        protocol_owner: protocol_owner,
                        task_description: task_description,
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
