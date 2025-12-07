package main

import (
	"bufio"
	"errors"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
)

var pageTpl = template.Must(template.New("index").Parse(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>emojiEncriptor</title>
</head>
<body>
    <h1>emojiEncriptor</h1>
    <form method="POST" action="/process">
        <label>
            Base symbol (emoji or letter):
            <input type="text" name="base" value="{{.Base}}" maxlength="4">
        </label>
        <br><br>
        <textarea name="text" rows="5" cols="40">{{.Input}}</textarea><br><br>
        <label>
            <input type="radio" name="mode" value="encode" {{if eq .Mode "encode"}}checked{{end}}> Encode
        </label>
        <label>
            <input type="radio" name="mode" value="decode" {{if eq .Mode "decode"}}checked{{end}}> Decode
        </label>
        <br><br>
        <button type="submit">Run</button>
    </form>

    {{if .Error}}
    <p style="color: red">{{.Error}}</p>
    {{end}}

    {{if .Output}}
    <h2>Result:</h2>
    <pre>{{.Output}}</pre>
    {{end}}
</body>
</html>
`))

const (
	variationSelectorStart           rune = 0xFE00
	variationSelectorEnd             rune = 0xFE0F
	variationSelectorSupplementStart rune = 0xE0100
	variationSelectorSupplementEnd   rune = 0xE01EF
)

const emojiChoices = "😀😃😄😁😆😅😂🤣☺😊😇🙂🙃😉😌😍😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🤩😏😒😞😔😟😕🙁☹️😣😖😫😩😢😭😤😠😡🤬🤯😳😱😨😰😥😓🤗🤔🤭🤫🤥😶😐😑😬🙄😯😦😧😮😲😴🤤😪😵🤐🤢🤮🤧😷🤒🤕🤑🤠😈👍👎"

func toVariationSelector(b byte) rune {
	if b < 16 {
		return variationSelectorStart + rune(b)
	}
	return variationSelectorSupplementStart + rune(b-16)
}

func fromVariationSelector(r rune) (byte, bool) {
	switch {
	case r >= variationSelectorStart && r <= variationSelectorEnd:
		return byte(r - variationSelectorStart), true
	case r >= variationSelectorSupplementStart && r <= variationSelectorSupplementEnd:
		return byte(r - variationSelectorSupplementStart + 16), true
	default:
		return 0, false
	}
}

func encode(base, text string) (string, error) {
	if base == "" {
		return "", errors.New("base symbol is required")
	}

	var builder strings.Builder
	builder.WriteString(base)

	for _, b := range []byte(text) {
		builder.WriteRune(toVariationSelector(b))
	}

	return builder.String(), nil
}

func decode(text string) []string {
	var messages []string
	var block []byte
	inBlock := false

	for _, r := range text {
		if b, ok := fromVariationSelector(r); ok {
			block = append(block, b)
			inBlock = true
			continue
		}

		if inBlock && len(block) > 0 {
			messages = append(messages, string(block))
			block = block[:0]
			inBlock = false
		}
	}

	if len(block) > 0 {
		messages = append(messages, string(block))
	}

	return messages
}

func prompt(reader *bufio.Reader, message string) (string, error) {
	fmt.Print(message)
	input, err := reader.ReadString('\n')
	if errors.Is(err, io.EOF) {
		return strings.TrimSpace(input), nil
	}
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(input), nil
}

func runRussian(reader *bufio.Reader) {
	fmt.Println("Выберите режим:")
	fmt.Println("1 - Кодирование")
	fmt.Println("2 - Декодирование")

	choice, err := prompt(reader, "Ваш выбор: ")
	if err != nil {
		fmt.Println("Ошибка ввода:", err)
		os.Exit(1)
	}

	switch choice {
	case "1":
		fmt.Println(emojiChoices)
		base, err := prompt(reader, "Введи один символ для кодирования (смайлик или буква): ")
		if err != nil {
			fmt.Println("Ошибка ввода:", err)
			os.Exit(1)
		}

		msg, err := prompt(reader, "Введи сообщение для кодирования: ")
		if err != nil {
			fmt.Println("Ошибка ввода:", err)
			os.Exit(1)
		}

		encoded, err := encode(base, msg)
		if err != nil {
			fmt.Println("Ошибка:", err)
			os.Exit(1)
		}

		fmt.Println("Закодировано:", encoded)
	case "2":
		encodedInput, err := prompt(reader, "Введи зашифрованное сообщение (в нём может быть несколько блоков): ")
		if err != nil {
			fmt.Println("Ошибка ввода:", err)
			os.Exit(1)
		}

		decoded := decode(encodedInput)
		fmt.Print("Декодировано: ")
		fmt.Println(strings.Join(decoded, " "))
	default:
		fmt.Println("Неверный выбор. Введите 1 или 2.")
		os.Exit(1)
	}
}

func runEnglish(reader *bufio.Reader) {
	fmt.Println("Select mode:")
	fmt.Println("1 - Encoding")
	fmt.Println("2 - Decoding")

	choice, err := prompt(reader, "Your choice: ")
	if err != nil {
		fmt.Println("Input error:", err)
		os.Exit(1)
	}

	switch choice {
	case "1":
		fmt.Println(emojiChoices)
		base, err := prompt(reader, "Enter a single symbol for encoding (emoji or letter): ")
		if err != nil {
			fmt.Println("Input error:", err)
			os.Exit(1)
		}

		msg, err := prompt(reader, "Enter your message for encoding: ")
		if err != nil {
			fmt.Println("Input error:", err)
			os.Exit(1)
		}

		encoded, err := encode(base, msg)
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(1)
		}

		fmt.Println("Encoded:", encoded)
	case "2":
		encodedInput, err := prompt(reader, "Enter the encoded message (it may contain several blocks): ")
		if err != nil {
			fmt.Println("Input error:", err)
			os.Exit(1)
		}

		decoded := decode(encodedInput)
		fmt.Print("Decoded: ")
		fmt.Println(strings.Join(decoded, " "))
	default:
		fmt.Println("Invalid choice. Please enter 1 or 2.")
		os.Exit(1)
	}
}

type pageData struct {
	Input  string
	Output string
	Mode   string
	Base   string
	Error  string
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	data := pageData{Mode: "encode"}
	if err := pageTpl.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func processHandler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseForm(); err != nil {
		http.Error(w, "bad form", http.StatusBadRequest)
		return
	}

	text := r.Form.Get("text")
	mode := r.Form.Get("mode")
	base := r.Form.Get("base")
	if mode == "" {
		mode = "encode"
	}

	var (
		result string
		errMsg string
	)

	switch mode {
	case "encode":
		encoded, err := encode(base, text)
		if err != nil {
			errMsg = err.Error()
		} else {
			result = encoded
		}
	default:
		decoded := decode(text)
		result = strings.Join(decoded, " ")
	}

	data := pageData{
		Input:  text,
		Output: result,
		Mode:   mode,
		Base:   base,
		Error:  errMsg,
	}

	if err := pageTpl.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func main() {
	http.HandleFunc("/", indexHandler)
	http.HandleFunc("/process", processHandler)

	log.Println("Server listening on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}

// func main() {
// 	reader := bufio.NewReader(os.Stdin)

// 	fmt.Println("Выбери язык/Choose your language:")
// 	fmt.Println("Русский - '1'")
// 	fmt.Println("English - '2'")

// 	langChoice, err := prompt(reader, "Твой выбор/Your choice: ")
// 	if err != nil {
// 		fmt.Println("Input error:", err)
// 		os.Exit(1)
// 	}

// 	switch langChoice {
// 	case "1":
// 		runRussian(reader)
// 	case "2":
// 		runEnglish(reader)
// 	default:
// 		fmt.Println("Неверный выбор языка. Please choose 1 or 2.")
// 		os.Exit(1)
// 	}
// }
