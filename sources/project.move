module MyModule::OpenNotesGrants {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    /// Struct representing an open notes grant program.
    struct GrantProgram has store, key {
        total_pool: u64,        // Total grant pool available
        distributed: u64,       // Amount already distributed
        min_grant: u64,         // Minimum grant amount per recipient
        max_grant: u64,         // Maximum grant amount per recipient
    }

    /// Struct to track individual grant recipient status.
    struct GrantRecipient has store, key {
        amount_received: u64,   // Total amount received by this recipient
        notes_submitted: u64,   // Number of open notes/research submissions
    }

    /// Function to initialize a new grant program with funding pool.
    public fun create_grant_program(
        admin: &signer, 
        pool_amount: u64, 
        min_grant: u64, 
        max_grant: u64
    ) {
        let program = GrantProgram {
            total_pool: pool_amount,
            distributed: 0,
            min_grant,
            max_grant,
        };
        move_to(admin, program);
    }

    /// Function to distribute grants to qualified recipients based on open notes contributions.
    public fun distribute_grant(
        admin: &signer,
        recipient: address,
        grant_amount: u64,
        notes_count: u64
    ) acquires GrantProgram, GrantRecipient {
        let admin_addr = signer::address_of(admin);
        let program = borrow_global_mut<GrantProgram>(admin_addr);
        
        // Validate grant amount and availability
        assert!(grant_amount >= program.min_grant && grant_amount <= program.max_grant, 1);
        assert!(program.distributed + grant_amount <= program.total_pool, 2);
        assert!(notes_count > 0, 3);

        // Transfer grant to recipient
        let grant_coins = coin::withdraw<AptosCoin>(admin, grant_amount);
        coin::deposit<AptosCoin>(recipient, grant_coins);

        // Update program state
        program.distributed = program.distributed + grant_amount;

        // Update or create recipient record
        if (exists<GrantRecipient>(recipient)) {
            let recipient_data = borrow_global_mut<GrantRecipient>(recipient);
            recipient_data.amount_received = recipient_data.amount_received + grant_amount;
            recipient_data.notes_submitted = recipient_data.notes_submitted + notes_count;
        } else {
            let recipient_data = GrantRecipient {
                amount_received: grant_amount,
                notes_submitted: notes_count,
            };
            move_to(admin, recipient_data);
        };
    }
}