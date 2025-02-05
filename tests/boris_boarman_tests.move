#[test_only]
module boris_boarman::boris_boarman_tests {
    use sui::test_scenario as ts;
    use sui::coin;
    use sui::sui::SUI;
    use sui::clock;
    use boris_boarman::FundRelease::{Self, FundingProposals};

    // Test addresses
    const ADMIN: address = @0xAD;
    const USER1: address = @0x42;
    const USER2: address = @0x43;

    // Test constants
    const PROPOSAL_AMOUNT: u64 = 1000;
    const INITIAL_TIMESTAMP: u64 = 1000;

    // Test error codes
    const E_WRONG_PROPOSAL_CREATOR: u64 = 0;
    const E_WRONG_PROPOSAL_AMOUNT: u64 = 1;
    const E_WRONG_PROPOSAL_RECIPIENT: u64 = 2;

    // Test setup helper function
    fun setup_test(scenario: &mut ts::Scenario): clock::Clock {
        // Start with admin account
        ts::next_tx(scenario, ADMIN);
        {
            // Create and setup clock for testing
            let mut clock = clock::create_for_testing(ts::ctx(scenario));
            clock::set_for_testing(&mut clock, INITIAL_TIMESTAMP);
            FundRelease::test_init(ts::ctx(scenario));
            clock
        }
    }

    // Test cleanup helper function
    fun cleanup_test(clock: clock::Clock, scenario: ts::Scenario) {
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_create_proposal() {
        // Initialize scenario with ADMIN account
        let mut scenario = ts::begin(ADMIN);
        let clock = setup_test(&mut scenario);

        // Create a proposal as USER1
        ts::next_tx(&mut scenario, USER1);
        {
            let mut proposals = ts::take_shared<FundingProposals>(&scenario);
            FundRelease::create_proposal(&mut proposals, &clock, USER2, PROPOSAL_AMOUNT, ts::ctx(&mut scenario));
            ts::return_shared(proposals);
        };

        // Verify proposal was created correctly
        ts::next_tx(&mut scenario, USER1);
        {
            let proposals = ts::take_shared<FundingProposals>(&scenario);
            assert!(FundRelease::get_proposal_creator(&proposals, 0) == USER1, E_WRONG_PROPOSAL_CREATOR);
            assert!(FundRelease::get_proposal_amount(&proposals, 0) == PROPOSAL_AMOUNT, E_WRONG_PROPOSAL_AMOUNT);
            assert!(FundRelease::get_proposal_recipient(&proposals, 0) == USER2, E_WRONG_PROPOSAL_RECIPIENT);
            ts::return_shared(proposals);
        };

        cleanup_test(clock, scenario);
    }

    #[test]
    #[expected_failure(abort_code = FundRelease::EUnauthorized)]
    fun test_unauthorized_release() {
        // Initialize scenario with ADMIN account
        let mut scenario = ts::begin(ADMIN);
        let clock = setup_test(&mut scenario);

        // Create a proposal as USER1
        ts::next_tx(&mut scenario, USER1);
        {
            let mut proposals = ts::take_shared<FundingProposals>(&scenario);
            FundRelease::create_proposal(&mut proposals, &clock, USER2, PROPOSAL_AMOUNT, ts::ctx(&mut scenario));
            ts::return_shared(proposals);
        };

        // Try to release funds with non-admin account (should fail)
        ts::next_tx(&mut scenario, USER1);
        {
            let coin = coin::mint_for_testing<SUI>(PROPOSAL_AMOUNT, ts::ctx(&mut scenario));
            let mut proposals = ts::take_shared<FundingProposals>(&scenario);
            FundRelease::release_funds(&mut proposals, &clock, 0, coin, ts::ctx(&mut scenario));
            ts::return_shared(proposals);
        };

        cleanup_test(clock, scenario);
    }

    #[test]
    fun test_successful_release() {
        // Initialize scenario with ADMIN account
        let mut scenario = ts::begin(ADMIN);
        let clock = setup_test(&mut scenario);

        // Create a proposal as USER1
        ts::next_tx(&mut scenario, USER1);
        {
            let mut proposals = ts::take_shared<FundingProposals>(&scenario);
            FundRelease::create_proposal(&mut proposals, &clock, USER2, PROPOSAL_AMOUNT, ts::ctx(&mut scenario));
            ts::return_shared(proposals);
        };

        // Release funds as ADMIN (should succeed)
        ts::next_tx(&mut scenario, ADMIN);
        {
            let coin = coin::mint_for_testing<SUI>(PROPOSAL_AMOUNT, ts::ctx(&mut scenario));
            let mut proposals = ts::take_shared<FundingProposals>(&scenario);
            FundRelease::release_funds(&mut proposals, &clock, 0, coin, ts::ctx(&mut scenario));
            ts::return_shared(proposals);
        };

        // Verify USER2 received the funds
        ts::next_tx(&mut scenario, USER2);
        {
            let coin = ts::take_from_sender<coin::Coin<SUI>>(&scenario);
            assert!(coin::value(&coin) == PROPOSAL_AMOUNT, 0);
            ts::return_to_sender(&scenario, coin);
        };

        cleanup_test(clock, scenario);
    }
}
