%include "lib.inc"

global find_word
section .text

; Принимает указатель на нуль-терминированную строку в 1 аргументе
; Принимает указатель на начало словаря во 2 аргументе
; Возвращает адрес вхождения в словарь в случае успеха, 0 в случае неудачи
find_word:
; Итерируемся по всему списку, пока он не закончится или пока не найдем подходящий ключ
.zaloop:
    ; Сохраняем полученные аргументы
    push rdi
    push rsi

    ; Увеличиваем указатель на 8 байт, чтобы получить указатель на ключ
    add rsi, 8
    call string_equals

    ; Восстанавливаем полученные аргументы
    pop rsi
    pop rdi

    ; Проверяем совпадение ключа
    cmp rax, 1
    je .succass

    ; Проверяем, не является ли следующий элемент списка 0 (если является, то подходящего ключа нет)
    mov r8, [rsi]
    cmp r8, 0
    je .failed

    mov rsi, [rsi]
    jmp .zaloop
.succass:
    mov rax, rsi
    ret
.failed:
    xor rax, rax
    ret