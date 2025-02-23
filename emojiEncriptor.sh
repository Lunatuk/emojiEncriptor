#!/bin/bash

if ! command -v xxd &> /dev/null; then
    echo "Ошибка: xxd не найден. Установите vim с помощью 'sudo apt install vim' или 'sudo yum install vim'."
    echo "Error: xxd not found. Install vim using 'sudo apt install vim' or 'sudo yum install vim'."
    exit 1
fi

# Диапазоны variation selectors
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
        echo "Error: byte $byte is out of range 0-255" >&2
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
    local emoji="$1"
    local text="$2"
    local encoded="$emoji"

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
    local bytes=()

    while IFS= read -r -N1 char; do
        codepoint=$(printf '%d' "'$char")
        byte=$(from_variation_selector "$codepoint")
        if [[ $? -eq 0 ]]; then
            bytes+=("$byte")
        elif [[ ${#bytes[@]} -eq 0 ]]; then
            continue
        else
            break
        fi
    done < <(printf %s "$text")

    local byte_string=""
    for byte in "${bytes[@]}"; do
        byte_string+=$(printf '\\x%x' "$byte")
    done
    echo -e "$byte_string"
}

echo "Выбери язык/Choose your language:"
echo "Русский - '1'"
echo "English - '2'"
read -p "Твой выбор/Your choice: " lang_choice

case "$lang_choice" in
    1)
        echo "Выберите режим:"
        echo "1 - Кодирование"
        echo "2 - Декодирование"
        read -p "Ваш выбор: " choice
        case "$choice" in
            1)
                echo "😀😃😄😁😆😅😂🤣☺😊😇🙂🙃😉😌😍😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🤩😏😒😞😔😟😕🙁☹️😣😖😫😩😢😭😤😠😡🤬🤯😳😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲😴🤤😪😵🤐🤢🤮🤧😷🤒🤕🤑🤠😈👍👎"
                read -p "Выбери смайлик для кодирования (скопируй и вставь): " emoji
                read -p "Теперь введи свое сообщение для кодирования: " input_text
                encoded=$(encode "$emoji" "$input_text")
                echo "Закодировано: $encoded"
                ;;
            2)
                read -p "Введите закодированную строку: " encoded_text
                decoded=$(decode "$encoded_text")
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
                read -p "Choose an emoji for encoding (copy and paste): " emoji
                read -p "Now enter your message for encoding: " input_text
                encoded=$(encode "$emoji" "$input_text")
                echo "Encoded: $encoded"
                ;;
            2)
                read -p "Enter the encoded string: " encoded_text
                decoded=$(decode "$encoded_text")
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
