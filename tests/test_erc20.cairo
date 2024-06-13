use starknet::{
    contract_address_const, get_block_info, ContractAddress, Felt252TryIntoContractAddress, TryInto,
    Into, OptionTrait, class_hash::Felt252TryIntoClassHash, get_caller_address,
    get_contract_address,
};
use starknet::storage_read_syscall;


use snforge_std::{
    declare, start_prank, ContractClassTrait, spy_events, SpyOn, EventSpy, EventFetcher, Event,
    event_name_hash, EventAssertions, CheatTarget
};


use array::{ArrayTrait, SpanTrait, ArrayTCloneImpl};
use result::ResultTrait;
use serde::Serde;

use box::BoxTrait;
use integer::u256;

use token_sender::erc20::mock_erc20::MockERC20;

use token_sender::erc20::mock_erc20::MockERC20::{Event::ERC20Event};
use openzeppelin::token::erc20::ERC20Component;


use token_sender::erc20::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

const INITIAL_SUPPLY: u256 = 1000000000;


fn setup() -> ContractAddress {
    let erc20_class_hash = declare("MockERC20").unwrap();

    let account: ContractAddress = contract_address_const::<1>();

    let mut calldata = ArrayTrait::new();
    INITIAL_SUPPLY.serialize(ref calldata);
    account.serialize(ref calldata);

    let (contract_address, _) = erc20_class_hash.deploy(@calldata).unwrap();

    contract_address
}

#[test]
fn test_mint_increase_balance() {
    // Deploy the contract
    let contract_address = setup();

    // Create a dispatcher to interact with the deployed contract
    let erc20 = IERC20Dispatcher { contract_address };

    // Set any address to mint tokens to
    let addr: ContractAddress = contract_address_const::<
        0x12325ba8fb37c73cab1853c5808b9ee69193147413d21594a61581da64ff29d
    >();

    // Mint some tokens (replace 42 with the desired amount)
    erc20.mint(addr, 42);

    // // Check the recipient's balance after minting
    let balance_after = erc20.balance_of(addr);
    assert(balance_after == 42, 'Invalid balance');
}

#[test]
fn test_get_balance() {
    let contract_address = setup();
    let erc20 = IERC20Dispatcher { contract_address };

    let account: ContractAddress = contract_address_const::<1>();

    assert(erc20.balance_of(account) == INITIAL_SUPPLY, 'Balance should be > 0');
}

#[test]
fn test_transfer() {
    let contract_address = setup();
    let erc20 = IERC20Dispatcher { contract_address };

    let target_account: ContractAddress = contract_address_const::<2>();

    let balance_before = erc20.balance_of(target_account);
    assert(balance_before == 0, 'Invalid balance');

    start_prank(CheatTarget::One(contract_address), 1.try_into().unwrap());

    let transfer_value: u256 = 100;
    erc20.transfer(target_account, transfer_value);

    let balance_after = erc20.balance_of(target_account);
    assert(balance_after == transfer_value, 'No value transfered');
}

#[test]
#[fork(
    url: "https://starknet-sepolia.public.blastapi.io/rpc/v0_7", block_id: BlockId::Number(61804)
)]
fn test_fork_transfer() {
    let contract_address = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
        .try_into()
        .unwrap();
    let erc20 = IERC20Dispatcher { contract_address };

    let target_account: ContractAddress = contract_address_const::<2>();

    let owner_account: ContractAddress = contract_address_const::<
        0x04337e199aa6a8959aeb2a6afcd2f82609211104191a041e7b9ba2f4039768f0
    >();

    let balance_before = erc20.balance_of(target_account);
    assert(balance_before == 0, 'Invalid balance');

    start_prank(CheatTarget::One(contract_address), owner_account.try_into().unwrap());

    let transfer_value: u256 = 100;
    erc20.transfer(target_account, transfer_value);

    let balance_after = erc20.balance_of(target_account);
    assert(balance_after == transfer_value, 'No value transfered');
}

#[test]
fn test_transfer_event() {
    let contract_address = setup();
    let erc20 = IERC20Dispatcher { contract_address };

    let target_account: ContractAddress = contract_address_const::<2>();
    let token_sender: ContractAddress = contract_address_const::<1>();
    start_prank(CheatTarget::All, token_sender);

    let mut spy = spy_events(SpyOn::One(contract_address));

    let transfer_value: u256 = 100;
    erc20.transfer(target_account, transfer_value);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    ERC20Component::Event::Transfer(
                        ERC20Component::Transfer {
                            from: token_sender, to: target_account, value: transfer_value
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('u256_sub Overflow',))]
fn should_panic_transfer() {
    let contract_address = setup();
    let erc20 = IERC20Dispatcher { contract_address };

    let target_account: ContractAddress = contract_address_const::<2>();

    let balance_before = erc20.balance_of(target_account);
    assert(balance_before == 0, 'Invalid balance');

    start_prank(CheatTarget::One(contract_address), 1.try_into().unwrap());

    let transfer_value: u256 = 1000000001;

    erc20.transfer(target_account, transfer_value);
}

