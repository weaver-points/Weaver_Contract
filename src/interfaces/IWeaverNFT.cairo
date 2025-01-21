use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of WEAVER NFT
// *************************************************************************
#[starknet::interface]
pub trait IWeaverNFT<TState> {
    fn mint_weaver_nft(ref self: TState, address: ContractAddress);
    fn get_last_minted_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, user: ContractAddress) -> u256;
    fn get_token_mint_timestamp(self: @TState, token_id: u256) -> u64;
}