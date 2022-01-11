%include "lib.inc"
%include "dict.inc"
%include "words.inc"

%define BUFFER_SIZE 256

global _start

section .rodata
long_error: db "The key is too long", 0
found_error: db "No data was found for this key", 0
new_line_error: db 0xA, 0


section .text
_start:
    ; Откладываем буфер
    sub rsp, 256

    ; Читаем искомый ключ
    mov rdi, rsp
    mov rsi, BUFFER_SIZE
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
    xor rdi, rdi
    call .exit_from_search
.long_error:
    mov rdi, long_error
    call print_error

    mov rdi, new_line_error
    call print_error

    mov rdi, 1
    call .exit_from_search
.found_error:
    mov rdi, found_error
    call print_error

    mov rdi, new_line_error
    call print_error

    mov rdi, 1
    call .exit_from_search
.exit_from_search:
    add rsp, 256
    call exit