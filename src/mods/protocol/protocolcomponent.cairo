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
    use crate::mods::interfaces::IERC721::{IERC721Dispatcher,IERC721DispatcherTrait};

    use crate::mods::errors::Errors;
    use crate::mods::types::ProtocolDetails;
    use crate::mods::types::CampaignMembers;

    

    #[storage]
    pub struct Storage {
        protocol_id: u256,
        protocol_counter: u256,
        protocol_nft_class_hash: ClassHash,
        protocol_owner: Map<u256,ContractAddress>,
        protocols: Map<u256, ProtocolDetails>,
        protocol_initialized: Map<u256, bool>,
        users_count: u256,
        Campaign_members: Map<(u256, ContractAddress),CampaignMembers>



    }


     // *************************************************************************
    //                            EVENT
    // *************************************************************************


    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ProtocolCampaign:ProtocolCampaign, 
        JoinProtocolCampaign: JoinProtocolCampaign,

    }


    #[derive(Drop, starknet::Event)]
    pub struct ProtocolCampaign{
       pub protocol_id:u256,
       pub protocol_owner: ContractAddress,
       pub  protocol_nft_address: ContractAddress,
       pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoinProtocolCampaign{
        pub protocol_id:u256,
        pub caller: ContractAddress,
        pub token_id: u256,
        pub user: ContractAddress,
        pub block_timestamp:u64,
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

    >of PrivateTrait<TContractState>{

        // @notice initialize protocol component 
        // protocol_nft_class_hash: classhash of protocol nft 

        fn _initialize(ref self: ComponentState<TContractState>, protocol_nft_class_hash:felt252){
            self.protocol_counter.write(0);
            self.protocol_nft_class_hash.write(protocol_nft_class_hash.try_into().unwrap());
        }


        // @notice create protocol campaign 
        //

        fn _protocol_campaign(
            ref self:  ComponentState<TContractState>,
            protocol_owner: ContractAddress,
            protocol_nft_address: ContractAddress,
            protocol_id: u256
        ) {

            // write to storage 

            let protocol_details = ProtocolDetails {
                protocol_id: protocol_id,
                protocol_owner: protocol_owner,
                protocol_matadata_uri: "",
                protocol_nft_address: protocol_nft_address,
                protocol_campaign_members: 0,

            };

            self.protocols.write(protocol_id,protocol_details);
            self.protocol_initialized.write(protocol_id, true);
            self.protocol_owner.write(protocol_id,protocol_owner);
            self.protocol_counter.write(protocol_id);


            // emit event after creating protocol creates campaign

            self. emit(
                ProtocolCampaign{
                    protocol_id:protocol_id,
                    protocol_owner:protocol_owner,
                    protocol_nft_address:protocol_nft_address,
                    block_timestamp:get_block_timestamp()
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
        ){
            // mint protocol nft to the new user joining the campaign 
            let minted_token_id = self._mint_protocol_nft(user, protocol_nft_address);

            let Campaign_members = CampaignMembers{
                user_address: user,
                protocol_id: protocol_id,
                protocol_token_id: minted_token_id,
            };

            // Update storage 
            self.Campaign_members.write((protocol_id,user),Campaign_members);

            let protocol = self.protocols.read(protocol_id);
            let protocol_campaign_members = protocol.protocol_campaign_members+1;

            // update the protocol details 
            let update_protocol_details = ProtocolDetails{
                protocol_campaign_members: protocol_campaign_members, ..protocol
            };

            // update states 
            self.protocols.write(protocol_id,update_protocol_details);

            self.emit(
                JoinProtocolCampaign{
                    protocol_id:protocol_id,
                    caller:user,
                    token_id:minted_token_id,
                    user:user,
                    block_timestamp:get_block_timestamp()
                }
            );
        }



        //@notice mint protocol nft to users who wants to participate on protocol campaign
        // user: user to mint to 
        //protocol_nft_address: Address of the protocol nft

        fn _mint_protocol_nft(
            ref self: ComponentState<TContractState>,
            user: ContractAddress,
            protocol_nft_address: ContractAddress
        ) -> u256 {
            let token_id = ICustomNFTDispatcher { contract_address: protocol_nft_address}
            .mint_nft(user);

          return token_id;

        }

    }
}
