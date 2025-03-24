use weaver_contract::mods::protocol::protocolcomponent::ProtocolCampagin;
use weaver_contract::mods::protocol::protocols::protocols;


type TestingState = ProtocolCampagin::ComponentState<protocols::ContractState>;

impl TestingStateDefault of Default<TestingState> {
    fn default() -> TestingState {
        ProtocolCampagin::component_state_for_testing()
    }
}

#[test]
fn test_internal() {
    let mut protocol: TestingState = Default::default();
}
