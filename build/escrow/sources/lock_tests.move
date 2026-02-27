#[test_only]
module escrow::lock_tests {
    use sui::coin;
    use sui::test_scenario as ts;
    use sui::sui::SUI;

    use escrow::lock;

    const Bob: address = @0xA;

    #[test]
    fun test_lock_unlock() {
        let mut ts = ts::begin(Bob);
        let coin = coin::mint_for_testing<SUI>(42, ts.ctx());

        let (lock, key) = lock::lock(coin, ts.ctx());
        let coin = lock.unlock(key);

        coin.burn_for_testing();
        ts.end();
    }

    #[test]
    #[expected_failure(abort_code = lock::ELockKeyMismatch)]
    fun test_lock_key_mismatch() {
        let mut ts = ts::begin(Bob);
        let coin = coin::mint_for_testing<SUI>(42, ts.ctx());
        let another_coin = coin::mint_for_testing<SUI>(42, ts.ctx());

        let (l, _k) = lock::lock(coin, ts.ctx());
        let (_l, k) = lock::lock(another_coin, ts.ctx());

        let _key = l.unlock(k);
        abort 1337
    }
}