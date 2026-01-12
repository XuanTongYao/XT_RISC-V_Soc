symbols_list = [
    "rvtest_entry_point",
    "begin_signature",
    "end_signature",
    "tohost",
    "fromhost",
]
symbols_dict = {symbol: f"$${symbol}" for symbol in symbols_list}


simulate_plusargs_dict = {
    "firmware": "das",
    "signature": "dasd.sig",
    # **symbols_dict,
}


for symbol in symbols_list:
    simulate_plusargs_dict.update({symbol: f"$${symbol}"})


print(simulate_plusargs_dict)
