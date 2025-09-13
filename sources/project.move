module MyModule::NFTCalendar {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use std::string::String;

    /// Struct representing an NFT calendar event.
    struct CalendarEvent has store, key {
        event_id: u64,           // Unique identifier for the event
        title: String,           // Title of the event
        event_date: u64,         // Unix timestamp for the event date
        ticket_price: u64,       // Price per NFT ticket in APT
        total_tickets: u64,      // Total number of NFT tickets available
        sold_tickets: u64,       // Number of tickets sold
        creator: address,        // Address of the event creator
    }

    /// Error codes
    const E_EVENT_NOT_FOUND: u64 = 1;
    const E_SOLD_OUT: u64 = 2;
    const E_INSUFFICIENT_PAYMENT: u64 = 3;
    const E_EVENT_EXPIRED: u64 = 4;

    /// Function to create a new calendar event with NFT ticketing.
    public fun create_event(
        creator: &signer,
        event_id: u64,
        title: String,
        event_date: u64,
        ticket_price: u64,
        total_tickets: u64
    ) {
        let creator_address = signer::address_of(creator);
        let event = CalendarEvent {
            event_id,
            title,
            event_date,
            ticket_price,
            total_tickets,
            sold_tickets: 0,
            creator: creator_address,
        };
        move_to(creator, event);
    }

    /// Function for users to purchase NFT tickets for the calendar event.
    public fun purchase_ticket(
        buyer: &signer,
        event_creator: address,
        payment_amount: u64
    ) acquires CalendarEvent {
        let event = borrow_global_mut<CalendarEvent>(event_creator);
        let current_time = timestamp::now_seconds();
        
        // Check if event hasn't expired
        assert!(current_time < event.event_date, E_EVENT_EXPIRED);
        
        // Check if tickets are still available
        assert!(event.sold_tickets < event.total_tickets, E_SOLD_OUT);
        
        // Check if payment is sufficient
        assert!(payment_amount >= event.ticket_price, E_INSUFFICIENT_PAYMENT);
        
        // Transfer payment from buyer to event creator
        let payment = coin::withdraw<AptosCoin>(buyer, event.ticket_price);
        coin::deposit<AptosCoin>(event_creator, payment);
        
        // Update sold tickets count
        event.sold_tickets = event.sold_tickets + 1;
    }
}