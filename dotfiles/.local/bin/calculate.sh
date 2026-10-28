#!/bin/bash

is_hex() {
    [[ $1 == 0x* ]]
}

convert_to_decimal() {
    local num=$1
    if is_hex "$num"; then
        echo $((num))
    else
        echo $num
    fi
}

while true; do
    read -p "> " calculation
    read -r num1 operator num2 <<< "$calculation"

    dec1=$(convert_to_decimal "$num1")
    dec2=$(convert_to_decimal "$num2")

    result=$(echo "$dec1 $operator $dec2" | bc)
    printf "%d ( 0x%X )\n" "$result" "$result"
done
