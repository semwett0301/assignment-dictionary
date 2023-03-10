section .text

global exit
global string_length
global print_string
global print_char
global print_newline
global print_uint
global print_int
global string_equals
global read_char
global read_word
global parse_uint
global parse_int
global string_copy
global print_error

%define stdout 1
%define stderr 2

; Принимает код возврата и завершает текущий процесс
exit:
    mov rax, 60
    syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
    xor rax, rax
.loop:
    cmp byte [rdi+rax], 0 ; сравниваем текцщий символ с 0
    je .return
    inc rax
    jmp .loop
.return:
    ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
    mov rsi, rdi
    call string_length ; не сохраняем никакие caller-saved регистры, потому что они не участвуют в дальнейшем
    mov rdx, rax ; количество символов
    mov rax, 1 ; код системного вызова "write"
    mov rdi, stdout
    syscall
    ret

; Принимает код символа и выводит его в stdout
print_char:
    push rdi
    mov rsi, rsp
    mov rax, 1
    mov rdi, stdout
    mov rdx, 1
    syscall
    pop rdi
    ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
    mov rdi, 0xA
    call print_char ; не сохраняем никакие caller-saved регистры, потому что они не участвуют в дальнейшем
    ret

; Выводит беззнаковое 8-байтовое число в десятичном формате
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
    mov rax, rdi
    push 0 ; определяем в стеке начало строки
    mov r8, 10 ; определяем константу, на которую делим
.loop:
    xor rdx, rdx ; т.к. команда div в качестве старшего слова делимого использует rdx, он должен обнуляться каждую итерацию
                 ; (иначе она будет делить огромное число и результат будет либо неверным, либо вылезет ошибка, т.к. результат не поместится)
    div r8
    add rdx, 48 ; получаем ASCII од числа
    push rdx ; сохраняем полученный код в стек
    cmp rax, 0
    je .print_number ; если мы перебрали все число, то начинаем его печатать
    jmp .loop
.print_number:
    pop rdi
    cmp rdi, 0
    je .return ; сравниваем полученное число с концом строки (если конец, то завершаем работу)
    call print_char
    jmp .print_number
.return:
    ret

; Выводит знаковое 8-байтовое число в десятичном формате
print_int:
    mov rax, rdi
    cmp rax, 0
    jnl .print ; проверяем знак числа (если положительное, то сразу выводим)
    neg rax ; (получаем доп.код отрицательного числа)
    push rax ; (сохраняем caller-saved регистр)
    mov rdi, 45
    call print_char ; выводим -
    pop rax ; возвращаем доп.код изначального числа (теперь это аналогичное положительное число)
.print:
    mov rdi, rax
    call print_uint
    ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
    ; Сразу стоит отметить, что перед перебором строк можно было бы проверять и сравнивать их длины, но, так как
    ; процедура получения длины также итерирует строку, время выполнения от этой проверки упадет (если упадет)
    ; на крайне малую величину

    xor rcx, rcx ; обнуляем счетчик
.loop:
    ; выбрал регистры, потому что они не могут содержать переданные переменные по соглашению
    mov r10b, byte[rdi + rcx]
    mov r11b, byte[rsi + rcx] ; выбираем текущий символ в каждой строке
    cmp r10b, r11b
    jne .not_equals ; сравниваем символы

    cmp r10b, 0
    je .equals ; если символы были равны и хотя бы 1 из них - нуль-терминатор, то строки равны

    inc rcx
    jmp .loop ; увеличиваем счетчик и повторяем цикл

.equals:
    mov rax, 1
    ret
.not_equals:
    xor rax, rax
    ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
    mov r8, rsp ; сохраняем callee-saved регистр

    push 0
    mov rax, 0 ; системный вызов чтения
    mov rdi, 0 ; читаем из потока вывода
    mov rsi, rsp ; после прочтения кладем в стек
    mov rdx, 1 ; читаем 1 символ
    syscall
    pop rax

    mov rsp, r8 ; возвращаем callee-saved регистр
    ret

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
    xor rcx, rcx ; очищаем счетчик цикла
.loop:
    push rdi
    push rsi
    push rcx ; сохраняем caller-saved регистры (начало буфера, размер буфера, счетчик)

    call read_char

    pop rcx
    pop rsi
    pop rdi ; возвращаем caller-saved регистры

    cmp rax, 0 ; смотрим, закончился ли поток вывода
    je .success

    cmp rcx, rsi ; сравниваем счетчик с размером буфера
    je .failure

    cmp rcx, 0
    jne .check_space_and_add_new_char

    ; Проверка пробелов в начале
    cmp rax, 0x20 ; сравниваем с пробелом
    je .loop

    cmp rax, 0x9 ; сравниваем с табуляцией
    je .loop

    cmp rax, 0xa ; сравниваем с переводом строки
    je .loop


.check_space_and_add_new_char:
    ; Проверка пробелов после появления 1 символа
    cmp rax, 0x20 ; сравниваем с пробелом
    je .success

    cmp rax, 0x9 ; сравниваем с табуляцией
    je .success

    cmp rax, 0xa ; сравниваем с переводом строки
    je .success

    mov [rdi+rcx], rax ; записываем новый символ в буфер
    inc rcx ; увеличиваем счетчик

    jmp .loop

.success:
    mov byte[rdi+rcx], 0 ; добавляем нуль-терминант
    mov rax, rdi
    mov rdx, rcx
    ret

.failure:
    xor rax, rax
    ret


; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
    xor rcx, rcx ; очищаем нужные региcтры
    xor rax, rax
    xor rdx, rdx
    xor r9, r9
    mov r8, 10 ; вводим константу
.loop:
    mov r9b, byte[rdi+rcx] ; достаем 1 символ

    sub r9, 48 ; переодим из ASCII
    cmp r9, 0 ; убеждаемся, что это число
    jb .end_parse
    cmp r9, 9
    ja .end_parse

    inc rcx ; увеличиваем счетчик
    mul r8
    add rax, r9 ; умножаем на 10 предыдущее число и добавляем новое
    jmp .loop
.end_parse:
    mov rdx, rcx
    ret





; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был)
; rdx = 0 если число прочитать не удалось
parse_int:
    xor rdx, rdx
    xor rax, rax
    cmp byte[rdi], byte 45 ; проверяем минус
    je .parse_neg
.parse_pos:
    call parse_uint
    ret
.parse_neg:
    inc rdi
    call parse_uint
    neg rax ; переводим в отрицательное число (доп.код)
    inc rdx ; добавляем минус в количество
    ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
    xor rcx, rcx ; обнуляем счетчик (выбрал счетчиком стандартный регистр, т.к. функция получает только 3 аргумента)
.loop:
    mov r10b, [rdi + rcx]
    mov [rsi + rcx], r10b ; "перекладываем" текущий символ в буфер

    inc rcx
    cmp rcx, rdx
    ja .length_less_then_string ; увеличиваем счетчик и смотрим, больше ли он размера буфера (если да, то мы вернем 0)

    cmp r10, 0
    jne .loop ; смотрим, дошли ли мы до нуль-терминатора

    mov rax, rcx ; возвращаем длину
    ret

.length_less_then_string:
    xor rax, rax
    ret

; Принимает указатель на нуль-терминированную строку
; Выводит ее в stderr
print_error:
    push rdi
    call string_length
    pop rdi

    mov rsi, rdi
    mov rdx, rax
    mov rax, 1
    mov rdi, stderr
    syscall
    ret
