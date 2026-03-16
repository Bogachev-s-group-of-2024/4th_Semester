# Требования к программам

## 1. Структуры данных

В программе должны быть реализованы следующие структуры данных. :contentReference[oaicite:0]{index=0}

### Enum class — условия для полей

```cpp
#ifndef condition_H
#define condition_H

enum class condition
{
    none,   // not specified
    eq,     // equal
    ne,     // not equal
    lt,     // less than
    gt,     // greater than
    le,     // less equal
    ge,     // greater equal
    like,   // strings only: match pattern
    nlike,  // strings only: not match pattern
};

#endif
```

---

### Enum class — порядок вывода полей

```cpp
#ifndef ordering_H
#define ordering_H

enum class ordering
{
    none,   // not specified
    name,   // print name
    phone,  // print phone
    group,  // print group
};

#endif
```

---

### Контейнер данных объектов типа `record`

```cpp
#ifndef record_H
#define record_H

#include <memory>
#include <stdio.h>
#include "condition.h"
#include "ordering.h"

enum class io_status
{
    success,
    eof,
    format,
    memory,
    open,
    create,
};

class record
{
private:
    std::unique_ptr<char[]> name = nullptr;
    int phone = 0;
    int group = 0;

public:
    record() = default;
    ~record() = default;

    const char *get_name() const { return name.get(); }
    int get_phone() const { return phone; }
    int get_group() const { return group; }

    int init(const char *n, int p, int g);

    // move constructor
    record(record &&x) = default;

    // move assignment
    record& operator=(record&& x) = default;

    // prohibit copy
    record(const record &x) = delete;
    record& operator=(const record&) = delete;

    bool compare_name(condition x, const record& y) const;
    bool compare_phone(condition x, const record& y) const;
    bool compare_group(condition x, const record& y) const;

    void print(const ordering order[] = nullptr, FILE *fp = stdout);
    io_status read(FILE *fp = stdin);
};

#endif
```

Функции сравнения проверяют соответствие поля записи условию.

---

### Enum class — логические операции

```cpp
#ifndef operation_H
#define operation_H

enum class operation
{
    none,
    land,   // logical AND
    lor,    // logical OR
};

#endif
```

---

### Enum class — тип команды

```cpp
#ifndef command_type_H
#define command_type_H

enum class command_type
{
    none,
    quit,
    insert,
    select,
    del,
};

#endif
```

---

### Класс `command`

```cpp
#ifndef command_H
#define command_H

#include <stdio.h>
#include "record.h"
#include "operation.h"
#include "ordering.h"
#include "command_type.h"

class command : public record
{
private:
    static const int max_items = 3;

    command_type type = command_type::none;

    condition c_name = condition::none;
    condition c_phone = condition::none;
    condition c_group = condition::none;

    operation op = operation::none;

    ordering order[max_items] = {};
    ordering order_by[max_items] = {};

public:
    command() = default;
    ~command() = default;

    bool parse(const char *string);
    void print(FILE *fp = stdout) const;

    bool apply(const record& x) const;
};

#endif
```

---

## 2. Пример реализации функций класса `record`

```cpp
#include <string.h>
#include <stdio.h>
#include "record.h"

#define LEN 1234

int record::init(const char *n, int p, int g)
{
    phone = p;
    group = g;

    if (n)
    {
        name = make_unique<char[]>(strlen(n) + 1);
        if (!name) return -1;
        strcpy(name.get(), n);
    }
    else
    {
        name = nullptr;
    }

    return 0;
}
```

---

### Чтение записи

```cpp
io_status record::read(FILE *fp)
{
    char buf[LEN];

    name = nullptr;

    if (fscanf(fp, "%s%d%d", buf, &phone, &group) != 3)
    {
        if (feof(fp))
            return io_status::eof;

        return io_status::format;
    }

    if (init(buf, phone, group))
        return io_status::memory;

    return io_status::success;
}
```

---

### Вывод записи

```cpp
void record::print(const ordering order[], FILE *fp)
{
    const int max_items = 3;

    const ordering default_ordering[max_items] =
    {
        ordering::name,
        ordering::phone,
        ordering::group
    };

    const ordering *p = (order ? order : default_ordering);

    for (int i = 0; i < max_items; i++)
    {
        switch (p[i])
        {
            case ordering::name:
                printf(" %s", name.get());
                break;

            case ordering::phone:
                printf(" %d", phone);
                break;

            case ordering::group:
                printf(" %d", group);
                break;

            case ordering::none:
                continue;
        }
    }

    fprintf(fp, "\n");
}
```

---

### Пример сравнения

```cpp
bool record::compare_phone(condition x, const record& y) const
{
    switch (x)
    {
        case condition::none: return true;
        case condition::eq: return phone == y.phone;
        case condition::ne: return phone != y.phone;
        case condition::lt: return phone < y.phone;
        case condition::gt: return phone > y.phone;
        case condition::le: return phone <= y.phone;
        case condition::ge: return phone >= y.phone;
        case condition::like: return false;
    }

    return false;
}
```

---

# 3. Задача программы

Программа должна:

* построить **двунаправленный список** объектов `record`
* считать список из файла (аргумент командной строки)
* читать команды из **stdin**
* применять команды к списку
* выводить найденные записи в **stdout**

---

# 4. Формат команд

Разделитель команд:

```
;
```

Разделители аргументов:

* пробел
* табуляция
* перевод строки

---

## Команды

### Завершение программы

```
quit;
```

---

### Добавление записи

```
insert (<name>, <phone>, <group>);
```

---

### Поиск записей

```
select <fields> [where <condition>] [order by <fields>];
```

---

### Удаление записей

```
delete [where <condition>];
```

---

# 5. Условия вывода полей

```
<field>, <field>, ...
```

или

```
*
```

Пример:

```
group, name
```

---

# 6. Условия сортировки

```
order by name
order by name, phone
order by name, phone, group
```

Сортировка выполняется по возрастанию.

---

# 7. Условия поиска

Форматы:

```
field operator value
```

```
field1 ... and field2 ...
```

```
field1 ... or field2 ...
```

Максимум **3 условия**.

---

# 8. Условия на поле

### Сравнение

```
=
<>
<
>
<=
>=
```

---

### LIKE

```
name like St%
```

Спецсимволы:

| символ  | значение                  |
| ------- | ------------------------- |
| `_`     | любой один символ         |
| `%`     | любое количество символов |
| `[n-m]` | диапазон символов         |

---

### NOT LIKE

```
name not like St%
```

---

# 9. Примеры команд

Добавление:

```
insert (Student, 1234567, 209);
```

Поиск:

```
select group, name where phone = 1234567 and name = Student;
```

```
select * where phone >= 1234567 and name like St% order by group;
```

```
select name, phone where group = 209 and phone <> 1234567;
```

```
select * where name = Student or phone = 1234567;
```

```
select name where name not like St% and phone = 1234567 and group = 209 order by name;
```

```
select * order by name, phone, group;
```

Удаление:

```
delete where name = Student;
```

```
delete where phone = 1234567 and group = 209 and name not like Student;
```

---

# 10. Запуск программы

Программа принимает:

```
./program filename
```

Пример:

```
cat commands.txt | ./a.out a.txt > result.txt
```

Где:

* `commands.txt` — команды
* `a.txt` — файл со списком
* `result.txt` — результат работы

---

# 11. Формат вывода программы

В конце выполнения программа выводит:

```cpp
printf("%s : Result = %d Elapsed = %.2f\n", argv[0], res, t);
```

где

| параметр | значение                       |
| -------- | ------------------------------ |
| argv[0]  | имя программы                  |
| res      | количество найденных элементов |
| t        | время выполнения               |

---

# 12. Формат входного файла

Файл содержит записи:

```
Word1 1234567 209
Word2 2345678 101
Word3 9876543 301
```

Формат строки:

```
<name> <phone> <group>
```

* `name` — строка без пробелов
* `phone` — целое число
* `group` — целое число

Все записи уникальны.

---

# 13. Требования к реализации

Программа должна поддерживать:

1. `order by` в `select`
2. команду `insert`
3. команду `delete`
4. обработку всех команд в одном потоке

