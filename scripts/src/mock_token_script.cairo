use sncast_std::{
    declare, deploy, invoke, call, DeclareResult, DeployResult, InvokeResult, CallResult, get_nonce,
};
use starknet::{
    get_caller_address, contract_address_const, ContractAddress, get_contract_address, Into
};
use token_sender::erc20::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};


const INITIAL_SUPPLY: u256 = 1000000000;

fn main() {
    let max_fee = 200000000000000000;
    let salt = 0x4;

    let account: ContractAddress = 0x64b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691
        .try_into()
        .expect('bad address');

    let declare_result = declare("MockERC20", Option::Some(max_fee), Option::None).unwrap();

    let class_hash_felt: felt252 = declare_result.class_hash.into();

    println!("Class hash: {}", class_hash_felt);

    let mut calldata = ArrayTrait::new();
    INITIAL_SUPPLY.serialize(ref calldata);
    account.serialize(ref calldata);

    let nonce = get_nonce('pending');
    let class_hash = declare_result.class_hash;
    let deploy_result = deploy(
        class_hash, calldata, Option::Some(salt), true, Option::Some(max_fee), Option::Some(nonce)
    )
        .unwrap();

    let deploy_address_felt: felt252 = deploy_result.contract_address.into();
    println!("Deployed to address: {}", deploy_address_felt);

    let deploy_address: ContractAddress = deploy_result.contract_address.into();

    let invoke_nonce = get_nonce('pending');
    let invoke_result = invoke(
        deploy_result.contract_address,
        selector!("transfer"),
        array![account.into(), 0x2, 0x0],
        Option::Some(max_fee),
        Option::Some(invoke_nonce)
    )
        .expect('invoke failed');

    println!("Invoke tx hash is: {}", invoke_result.transaction_hash);
// let erc20 = IERC20Dispatcher { contract_address: deploy_address };
// let transfer_value: u256 = 1;
// let invoke_res = erc20.transfer(account, transfer_value);
// k
// println!("{:?}", invoke_res);
}
