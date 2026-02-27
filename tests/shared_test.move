#[test_only]
module escrow::shared_test {
    use sui::coin::{Self, Coin};    
    use sui::sui::SUI;
    use sui::test_scenario::{Self as ts, Scenario};

    use escrow::shared;
    use escrow::lock;

    const BOB: address = @0x123;
    const ALICE: address = @0x1234;
    const DIANE: address = @0x12345;

    fun test_coin(ts: &mut Scenario): Coin<SUI> {
        coin::mint_for_testing<SUI>(42, ts.ctx())
    }

    #[test]
    fun test_sucessful_swap() {
        let mut ts = ts::begin(@0x0);

        let (coin_bob, key_bob) = {
            ts.next_tx(BOB);
            let c = test_coin(&mut ts);
            let cid = object::id(&c);
            let (lock, key) = lock::lock(c, ts.ctx());
            let kid = object::id(&key);
            transfer::public_transfer(lock, BOB);
            transfer::public_transfer(key, BOB);
            (cid, kid)
        };

        let coin_alice = {
            ts.next_tx(ALICE);
            let c = test_coin(&mut ts);
            let cid = object::id(&c);
            shared::create(c, key_bob, BOB, ts.ctx());
            cid
        };

        {
            ts.next_tx(BOB);
            let escrow: shared::Escrow<Coin<SUI>> = ts.take_shared();
            let key: lock::Key = ts.take_from_sender();
            let locked: lock::Locked<Coin<SUI>> = ts.take_from_sender();
            let c = escrow.swap(key, locked, ts.ctx());

            transfer::public_transfer(c, BOB);
        };

        ts.next_tx(@0x0);

        {
            let c: Coin<SUI> = ts.take_from_address_by_id(ALICE, coin_bob);
            ts::return_to_address(ALICE, c);
        };

        {
            let c: Coin<SUI> = ts.take_from_address_by_id(BOB, coin_alice);
            ts::return_to_address(BOB, c);
        };

        ts.end();
    }

    #[test]
    fun test_return_to_sender() {
        let mut ts = ts::begin(@0x0);

        let key_bob = {
            ts.next_tx(BOB);
            let c = test_coin(&mut ts);
            let (lock, key) = lock::lock(c, ts.ctx());
            let kid = object::id(&key);
            transfer::public_transfer(lock, BOB);
            transfer::public_transfer(key, BOB);
            kid
        };

        let coin_alice = {
            ts.next_tx(ALICE);
            let c = test_coin(&mut ts);
            let cid = object::id(&c);
            shared::create(c, key_bob, BOB, ts.ctx());
            cid
        };

        {
            ts.next_tx(ALICE);
            let escrow: shared::Escrow<Coin<SUI>> = ts.take_shared();
            let c = escrow.return_to_sender(ts.ctx());
            transfer::public_transfer(c, ALICE);
        };

        ts.next_tx(@0x0);
        {
            let c: Coin<SUI> = ts.take_from_address_by_id(ALICE, coin_alice);
            ts::return_to_address(ALICE, c);
        };

        ts.end();
    }

    #[test]
    #[expected_failure(abort_code = shared::EMismatchedSenderRecipient)]
    fun test_mismatch_sender() {
        let mut ts = ts::begin(@0x0);

        let key_bob = {
            ts.next_tx(BOB);
            let c = test_coin(&mut ts);
            let (lock, key) = lock::lock(c, ts.ctx());
            let kid = object::id(&key);
            transfer::public_transfer(lock, BOB);
            transfer::public_transfer(key, BOB);
            kid
        };

        {
            ts.next_tx(ALICE);
            let c = test_coin(&mut ts);
            shared::create(c, key_bob, BOB, ts.ctx());
        };

        {
            ts.next_tx(DIANE);
            let escrow: shared::Escrow<Coin<SUI>> = ts.take_shared();
            let c = escrow.return_to_sender(ts.ctx());
            transfer::public_transfer(c, DIANE);
        };

        abort 1337
    }

    #[test]
    #[expected_failure(abort_code = shared::EMismatchedExchangeObject)]
    fun test_mismatch_object() {
        let mut ts = ts::begin(@0x0);

        let key_bob = {
            ts.next_tx(BOB);
            let c = test_coin(&mut ts);
            let (lock, key) = lock::lock(c, ts.ctx());
            let kid = object::id(&key);
            transfer::public_transfer(lock, BOB);
            transfer::public_transfer(key, BOB);
            kid
        };

        let (lock_id2, key_bob2) = {
            ts.next_tx(BOB);
            let c = test_coin(&mut ts);
            let (lock, key) = lock::lock(c, ts.ctx());
            let lid = object::id(&lock);
            let kid = object::id(&key);
            transfer::public_transfer(lock, BOB);
            transfer::public_transfer(key, BOB);
            (lid, kid)
        };

        {
            ts.next_tx(ALICE);
            let c = test_coin(&mut ts);
            shared::create(c, key_bob, BOB, ts.ctx());
        };

        {
            ts.next_tx(BOB);
            let escrow: shared::Escrow<Coin<SUI>> = ts.take_shared();
            let key: lock::Key = ts.take_from_sender_by_id(key_bob2);
            let locked: lock::Locked<Coin<SUI>> = ts.take_from_sender_by_id(lock_id2);
            let c = escrow.swap(key, locked, ts.ctx());

            transfer::public_transfer(c, BOB);
        };

        abort 1337
    }

    #[test]
    fun test_return_to_sender_failed_swap() {}

    #[test]
    fun test_object_tamper() {}
}