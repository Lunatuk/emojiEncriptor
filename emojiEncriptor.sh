#!/bin/bash
if ! command -v xxd &> /dev/null; then
    echo "Ошибка: xxd не найден. Установите vim с помощью 'sudo apt install vim' или 'sudo yum install vim'."
    echo "Error: xxd not found. Install vim using 'sudo apt install vim' or 'sudo yum install vim'."
    exit 1
fi

VARIATION_SELECTOR_START=65024      # 0xFE00 
VARIATION_SELECTOR_END=65039        # 0xFE0F
VARIATION_SELECTOR_SUPPLEMENT_START=917760  # 0xE0100
VARIATION_SELECTOR_SUPPLEMENT_END=917999    # 0xE01EF

to_variation_selector() {
    local byte="$1"
    if (( byte >= 0 && byte < 16 )); then
        printf "\\U$(printf '%08x' $((VARIATION_SELECTOR_START + byte)))"
    elif (( byte >= 16 && byte < 256 )); then
        printf "\\U$(printf '%08x' $((VARIATION_SELECTOR_SUPPLEMENT_START + byte - 16)))"
    else
        echo "Ошибка: байт $byte вне диапазона 0-255" >&2
        exit 1
    fi
}

from_variation_selector() {
    local codepoint="$1"
    if (( codepoint >= VARIATION_SELECTOR_START && codepoint <= VARIATION_SELECTOR_END )); then
        echo $((codepoint - VARIATION_SELECTOR_START))
    elif (( codepoint >= VARIATION_SELECTOR_SUPPLEMENT_START && codepoint <= VARIATION_SELECTOR_SUPPLEMENT_END )); then
        echo $((codepoint - VARIATION_SELECTOR_SUPPLEMENT_START + 16))
    else
        return 1
    fi
}

encode() {
    local base="$1"
    local text="$2"
    local encoded="$base"
    local bytes
    bytes=$(echo -n "$text" | xxd -p | tr -d '\n' | fold -w2)
    for byte_hex in $bytes; do
        byte_dec=$((16#$byte_hex))
        encoded+=$(to_variation_selector "$byte_dec")
    done
    echo -e "$encoded"
}

decode() {
    local text="$1"
    local messages=()
    local current_bytes=()
    local in_block=false       

    while IFS= read -r -N1 char; do
        codepoint=$(printf '%d' "'$char")
        byte=$(from_variation_selector "$codepoint")
        if [[ $? -eq 0 ]]; then
            current_bytes+=("$byte")
            in_block=true
        else
            if $in_block && [ ${#current_bytes[@]} -gt 0 ]; then
                local byte_string=""
                for byte in "${current_bytes[@]}"; do
                    byte_string+=$(printf '\\x%x' "$byte")
                done
                messages+=("$(echo -e "$byte_string")")
                current_bytes=()
                in_block=false
            fi
        fi
    done < <(printf %s "$text")

    if [ ${#current_bytes[@]} -gt 0 ]; then
        local byte_string=""
        for byte in "${current_bytes[@]}"; do
            byte_string+=$(printf '\\x%x' "$byte")
        done
        messages+=("$(echo -e "$byte_string")")
    fi

    for msg in "${messages[@]}"; do
        echo -n "$msg "
    done
    echo
}

echo "Выбери язык/Choose your language:"
echo "Русский - '1'"
echo "English - '2'"
read -p "Твой выбор/Your choice: " lang_choice

#I only use case because I've never used it in bash scripts and I was wondering how it works here
case "$lang_choice" in
    1)
        echo "Выберите режим:"
        echo "1 - Кодирование"
        echo "2 - Декодирование"
        read -p "Ваш выбор: " choice
        case "$choice" in
            1)
                echo "😀😃😄😁😆😅😂🤣☺😊😇🙂🙃😉😌😍😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🤩😏😒😞😔😟😕🙁☹️😣😖😫😩😢😭😤😠😡🤬🤯😳😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲😴🤤😪😵🤐🤢🤮🤧😷🤒🤕🤑🤠😈👍👎"
                read -p "Введи один символ для кодирования (смайлик или буква): " base
                read -p "Введи сообщение для кодирования: " msg
                encoded=$(encode "$base" "$msg")
                echo "Закодировано: $encoded"
                ;;
            2)
                read -p "Введи зашифрованное сообщение (в нём может быть несколько блоков): " encoded_input
                decoded=$(decode "$encoded_input")
                echo "Декодировано: $decoded"
                ;;
            *)
                echo "Неверный выбор. Введите 1 или 2."
                exit 1
                ;;
        esac
        ;;
    2)
        echo "Select mode:"
        echo "1 - Encoding"
        echo "2 - Decoding"
        read -p "Your choice: " choice
        case "$choice" in
            1)
                echo "😀😃😄😁😆😅😂🤣☺😊😇🙂🙃😉😌😍😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🤩😏😒😞😔😟😕🙁☹️😣😖😫😩😢😭😤😠😡🤬🤯😳😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲😴🤤😪😵🤐🤢🤮🤧😷🤒🤕🤑🤠😈👍👎"
                read -p "Enter a single symbol for encoding (emoji or letter): " base
                read -p "Enter your message for encoding: " msg
                encoded=$(encode "$base" "$msg")
                echo "Encoded: $encoded"
                ;;
            2)
                read -p "Enter the encoded message (it may contain several blocks): " encoded_input
                decoded=$(decode "$encoded_input")
                echo "Decoded: $decoded"
                ;;
            *)
                echo "Invalid choice. Please enter 1 or 2."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Неверный выбор языка. Please choose 1 or 2."
        exit 1
        ;;
esac
