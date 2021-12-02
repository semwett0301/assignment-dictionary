%include "lib.inc"
%include "dict.inc"
%include "colon.inc"

global _start

section .rodata
%include "words.inc"
long_error: db "The key is too long", 0
found_error: db "No data was found for this key", 0

section .data
buffer: times 256 db 0

section .text
_start:
    ; Читаем искомый ключ
    mov rdi, buffer
    mov rsi, 256
    call read_word

    ; Проверяем ошибку длины ключа
    cmp rax, 0
    je .long_error

    ; Ищем ключ в словаре
    mov rdi, rax
    mov rsi, l_label
    call find_word

    ; Проверяем, был ли найден ключ
    cmp rax, 0
    je .found_error

    ; Смещаемся на 8 относительно вхождения и считаем длину ключа
    add rax, 8
    push rax
    mov rdi, rax
    call string_length
    mov rdi, rax
    pop rax

    ; Смещаемся на длину ключа + 1, чтобы получить указатель на значение, и выводим его
    add rdi, rax
    inc rdi
    call print_string
    call print_newline
    call exit
.long_error:
    mov rdi, long_error
    call print_error
    call print_newline
    call exit
.found_error:
    mov rdi, found_error
    call print_error
    call print_newline
    call exit


; Принимает указатель на нуль-терминированную строку
; Выводит ее в stderr
print_error:
    push rdi
    call string_length
    pop rdi

    mov rsi, rdi
    mov rdx, rax
    mov rax, 1
    mov rdi, 2
    syscall
    ret