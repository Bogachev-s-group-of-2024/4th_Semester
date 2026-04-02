# Группа 209 — задачи 06

| Фамилия | Имя | Задача |
|---|---|---:|
| Буровик | Е | 37 |
| Горонок | М | 11 |
| Грановский | А | 21 |
| Дармограй | Д | 13 |
| Егоров | Б | 19 |
| Зайцева | С | 3 |
| Иванов | Ю | 17 |
| Коломина | Т | 1 |
| Кочубей | Д | 35 |
| Крапивин | В | 5 |
| Криворученко | С | 7 |
| Кузьмичева | А | 15 |
| Куршина | С | 27 |
| Преображенсая | А | 25 |
| Рябов | А | 29 |
| Суставова | О | 31 |
| Туровцева | О | 33 |
| Ульянов | М | 23 |
| Чиченков | И | 9 |
| Ашуров | А | 11 |
| Климохин | К | 13 |
| Спицын | Д | 15 |
| Куцеборский | А | 17 |
| Скоркин | Д | 23 |
| Молчанов | В | 19 |

# Требования к программам

## 1. В программе должны быть реализованы следующие структуры данных

### Enum class, задающий условия для полей

```cpp
#ifndef condition_H
#define condition_H

enum class condition
{
    none,   // not specified
    eq,     // equal
    ne,     // not equal
    lt,     // less than
    gt,     // less than
    le,     // less equal
    ge,     // great equal
    like,   // strings only: match pattern
    nlike,  // strings only: not match pattern
};

#endif
````

### Enum class, задающий условия для вывода полей

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
    std::unique_ptr<char []> name = nullptr;
    int phone = 0;
    int group = 0;

public:
    record () = default;
    ~record () = default;

    const char * get_name () const { return name.get (); }
    int get_phone () const { return phone; }
    int get_group () const { return group; }

    int init (const char *n, int p, int g);

    // Allow as return value for functions
    record (record &&x) = default; // move constructor

    // Assignement move operator
    record& operator= (record&& x) = default;

    // Prohoibit pass by value
    // (it is default when move constructor is declared)
    record (const record &x) = delete;

    // Prohoibit assignement operator
    // (it is default when move constructor is declared)
    record& operator= (const record&) = delete;

    // Check condition 'x' for field 'name' for 'this' and 'y'
    bool compare_name (condition x, const record& y) const;

    // Check condition 'x' for field 'phone' for 'this' and 'y'
    bool compare_phone (condition x, const record& y) const;

    // Check condition 'x' for field 'group' for 'this' and 'y'
    bool compare_group (condition x, const record& y) const;

    void print (const ordering order[] = nullptr, FILE * fp = stdout);
    io_status read (FILE *fp = stdin);
};

#endif
```

Функции сравнения в этом классе сравнивают одно из полей класса с соответствующим полем класса `y` согласно условию, заданному аргументом `x`.

### Enum class, задающий логические операции для полей

```cpp
#ifndef operation_H
#define operation_H

enum class operation
{
    none, // not specified
    land, // logical and
    lor,  // logical or
};

#endif
```

### Enum class, задающий тип запроса

```cpp
#ifndef command_type_H
#define command_type_H

enum class command_type
{
    none,   // uninitialized
    quit,   // end of input stream
    insert, // add record
    select, // find by conditions specified
    del,    // delete record
};

#endif
```

### Класс, задающий условие для проверки

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
    ordering order[max_items] = { };
    ordering order_by[max_items] = { };

public:
    command () = default;
    ~command () = default;

    // Convert string command to data structure
    // Example: "select name, group where phone = 1234567 and name
    // like St% and group <> 208 order by group, name;"
    // parsed to
    // command::type = command_type::select,
    // command::name = "St%", command::c_name = condition::like,
    // command::phone = 1234567, command::c_phone = condition::eq,
    // command::group = 208, command::c_group = condition::ne,
    // command::op = operation::land,
    // command::order={ordering::name,ordering::group,ordering::none},
    // command::order_by={ordering::group,ordering::name,ordering::none}
    // other fields are unspecified
    bool parse (const char * string);

    // Print parsed structure
    void print (FILE *fp = stdout) const;

    // Apply command, return comparision result for record 'x'
    bool apply (const record& x) const;
};

#endif
```

---

## 2. Пример реализации некоторых функций из класса `record`

```cpp
#include <string.h>
#include <stdio.h>
#include "record.h"

#define LEN 1234

using namespace std;

int record::init (const char *n, int p, int g)
{
    phone = p;
    group = g;

    if (n)
    {
        name = make_unique<char []> (strlen (n) + 1);
        if (!name) return -1;
        strcpy (name.get(), n);
    }
    else
    {
        name = nullptr;
    }

    return 0;
}

io_status record::read (FILE *fp)
{
    char buf[LEN];
    name = nullptr;

    if (fscanf (fp, "%s%d%d", buf, &phone, &group) != 3)
    {
        if (feof(fp)) return io_status::eof;
        return io_status::format;
    }

    if (init (buf, phone, group))
        return io_status::memory;

    return io_statuss::success;
}

void record::print (const ordering order[], FILE *fp)
{
    const int max_items = 3;
    const ordering default_ordering[max_items]
        = {ordering::name, ordering::phone, ordering::group};

    const ordering * p = (order ? order : default_ordering);

    for (int i = 0; i < max_items; i++)
        switch (p[i])
        {
            case ordering::name:
                printf (" %s", name.get()); break;
            case ordering::phone:
                printf (" %d", phone); break;
            case ordering::group:
                printf (" %d", group); break;
            case ordering::none:
                continue;
        }

    fprintf (fp, "\n");
}

// Check condition 'x' for field 'phone' for 'this' and 'y'
bool record::compare_phone (condition x, const record& y) const
{
    switch (x)
    {
        case condition::none: // not specified
            return true; // unspecified opeation is true
        case condition::eq: // equal
            return phone == y.phone;
        case condition::ne: // not equal
            return phone != y.phone;
        case condition::lt: // less than
            return phone < y.phone;
        case condition::gt: // less than
            return phone > y.phone;
        case condition::le: // less equal
            return phone <= y.phone;
        case condition::ge: // great equal
            return phone >= y.phone;
        case condition::like: // strings only: match pattern
            return false; // cannot be used for phone
    }

    return false;
}
```

---

## 3. Задача программы

* Построить класс "База данных", содержащий контейнер объектов, то есть двунаправленный список, и структуры для быстрого поиска объектов.
* Построить двунаправленный список объектов типа `record` и считать его из указанного файла, переданного как аргумент командной строки.
* Считывать команды по одной со стандартного ввода `stdin`, пока команды не закончатся.
* Применять команду к списку и выводить только найденные в `select` элементы в стандартный вывод `stdout`, используя там, где возможно, структуры для быстрого поиска, а где невозможно, линейный просмотр списка.

---

## 4. Все команды имеют следующий вид

* Разделителем команд является `;`, разделителями аргументов команды являются пробел, символ табуляции и символ новой строки.
* `quit;` — завершить работу.
* `insert (<name>, <phone>, <group>);` — добавить объект типа `record` с указанными полями в список.
* `select <условия на выводимые поля> [where <условие поиска>] [order by <условия сортировки>];` — вывести элементы списка, удовлетворяющие условиям поиска, в указанном виде и в указанном порядке.
* `delete [where <условие поиска>];` — удалить элементы списка, удовлетворяющие указанным условиям. Если `where` отсутствует, удаляется весь список.

---

## 5. Условия на выводимые поля

* `<список полей>` — выводить указанные поля в указанном порядке. Список состоит из разделённых запятыми имён полей без повторений.
* `*` — выводить все поля, эквивалентно `name, phone, group`.

Пример:

```text
group, name
```

---

## 6. Условия сортировки

* `<список полей>` — выводить найденные записи в порядке возрастания указанного поля.
* Если значения первого поля совпадают, записи упорядочиваются по следующему полю, и так далее.
* Список состоит из разделённых запятыми имён полей без повторений.

Пример:

```text
name, phone
```

---

## 7. Условия поиска

Допустимые варианты:

* `<условие поиска на одно поле>`
* `<условие 1> and <условие 2>`
* `<условие 1> or <условие 2>`
* `<условие 1> and <условие 2> and <условие 3>`
* `<условие 1> or <условие 2> or <условие 3>`

Если в условии поиска участвует более одного условия, то они задаются на разные поля записи `record`.

---

## 8. Условие поиска на одно поле

### Общий вид

```text
<поле> <оператор> <выражение>
```

Где:

* `<поле>` — имя поля: `name`, `phone`, `value`
* `<оператор>` — логический оператор отношения:

  * `=`
  * `<>`
  * `<`
  * `>`
  * `<=`
  * `>=`
* `<выражение>` — константное выражение соответствующего типа

### Поиск по шаблону

```text
<поле> like <образец>
```

Где:

* `<поле>` — только поле символьного типа, то есть `name`
* `<образец>` — образец поиска

Специальные символы:

* `_` — соответствует одному любому символу
* `\_` и `\\` — литеральные символы `_` и `\`
* `%` — соответствует нулю или более любым символам
* `\%` и `\\` — литеральные символы `%` и `\`
* `[n-m]` — соответствует одному любому символу с кодом из диапазона `n...m`
* `\[`, `\]`, `\\` — литеральные символы `[`, `]`, `\`
* `[bn-m]` — соответствует любому символу, код которого не входит в диапазон `n...m`
* `\[`, `\]`, `\b`, `\\` — литеральные символы `[`, `]`, `b`, `\`

Условие считается выполненным, если поле соответствует образцу поиска.

### Отрицание шаблона

```text
<поле> not like <образец>
```

Условие считается выполненным, если поле не соответствует образцу поиска.

---

## 9. Примеры команд

```text
insert (Student, 1234567, 208);
```

Добавить запись с указанными полями.

```text
select group, name where phone = 1234567 and name = Student;
```

Вывести поля `group` и `name` для всех элементов списка, у которых поле `phone` равно `1234567`, а поле `name` равно `Student`.

```text
select * where phone >= 1234567 and name like St% order by group;
```

Вывести все поля для всех элементов списка, у которых `phone >= 1234567`, а `name` соответствует шаблону `St%`, и отсортировать результат по `group`.

```text
select name, phone where group = 208 and phone <> 1234567;
```

```text
select * where name = Student or phone = 1234567;
```

```text
select name where name not like St% and phone = 1234567 and group = 208 order by name;
```

```text
select * order by name, phone, group;
```

```text
delete where name = Student;
```

```text
delete where phone = 1234567 and group = 208 and name not like Student;
```

---

## 10. Параметры программы

Программа должна получать все параметры как аргументы командной строки и через стандартный ввод.

### Аргументы командной строки

1. `filename` — имя файла, откуда надо прочитать список.

Пример запуска:

```bash
cat commands.txt | ./a.out a.txt > result.txt
```

Это означает:

* файл `commands.txt` подаётся на стандартный ввод
* список читается из файла `a.txt`
* результаты перенаправляются из стандартного вывода в файл `result.txt`

---

## 11. Класс "список"

Класс "список" должен содержать функцию ввода списка из указанного файла.

---

## 12. Ввод списка из файла

В указанном файле находится дерево в формате:

```text
Слово-1 Целое-число-1 Целое-число-2
Слово-2 Целое-число-3 Целое-число-4
...
Слово-n Целое-число-2n-1 Целое-число-2n
```

Где:

* слово — последовательность алфавитно-цифровых символов без пробелов
* длина слова заранее неизвестна
* память под него выделяется динамически
* все записи в файле различны, то есть нет двух записей, у которых совпадают все три поля

Концом ввода считается конец файла.

Программа должна выводить сообщение об ошибке, если:

* указанный файл не может быть прочитан
* файл содержит данные неверного формата

---

## 13. Формат вывода результата в `main`

```cpp
printf ("%s : Result = %d Elapsed = %.2f\n", argv[0], res, t);
```

Где:

* `argv[0]` — первый аргумент командной строки, то есть имя программы
* `res` — общее количество найденных элементов списка
* `t` — время работы на все команды

Вывод должен быть строго в таком формате, чтобы можно было автоматизировать обработку запуска множества тестов.

---

# Задачи

Требуется написать программу, реализующую две из следующих структур для быстрого поиска объектов:

1. Динамический вектор векторов указанной длины `k`, упорядоченных по имени
2. Динамический вектор векторов указанной длины `k`, упорядоченных по номеру телефона
3. B-дерево по имени по указанному основанию `m`
4. B-дерево по номеру телефона по указанному основанию `m`
5. Упорядоченное сбалансированное дерево поиска по имени, AVL дерево
6. Упорядоченное сбалансированное дерево поиска по номеру телефона, AVL дерево
7. Упорядоченное красно-чёрное дерево поиска по имени
8. Упорядоченное красно-чёрное дерево поиска по номеру телефона
9. Хеш-реализация по указанным `k` первым буквам имени на базе массива списков объектов с одинаковым значением хеш-функции
10. Хеш-реализация по указанным `k` первым цифрам номера телефона на базе массива списков объектов с одинаковым значением хеш-функции
11. Хеш-реализация по указанным `k` последним буквам имени на базе массива списков объектов с одинаковым значением хеш-функции
12. Хеш-реализация по указанным `k` последним цифрам номера телефона на базе массива списков объектов с одинаковым значением хеш-функции
13. Хеш-реализация по сумме букв имени по указанному модулю `k` на базе массива списков объектов с одинаковым значением хеш-функции
14. Хеш-реализация по сумме цифр номера телефона по указанному модулю `k` на базе массива списков объектов с одинаковым значением хеш-функции
15. Хеш-реализация по указанным `k` первым буквам имени на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
16. Хеш-реализация по указанным `k` первым цифрам номера телефона на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
17. Хеш-реализация по указанным `k` последним буквам имени на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
18. Хеш-реализация по указанным `k` последним цифрам номера телефона на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
19. Хеш-реализация по сумме букв имени по указанному модулю `k` на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
20. Хеш-реализация по сумме цифр номера телефона по указанному модулю `k` на базе динамического вектора векторов указанной длины `m` объектов с одинаковым значением хеш-функции
21. Хеш-реализация по указанным `k` первым буквам имени на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
22. Хеш-реализация по указанным `k` первым цифрам номера телефона на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
23. Хеш-реализация по указанным `k` последним буквам имени на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
24. Хеш-реализация по указанным `k` последним цифрам номера телефона на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
25. Хеш-реализация по сумме букв имени по указанному модулю `k` на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
26. Хеш-реализация по сумме цифр номера телефона по указанному модулю `k` на базе B-дерева по указанному основанию `m` объектов с одинаковым значением хеш-функции
27. Хеш-реализация по указанным `k` первым буквам имени на базе AVL дерева объектов с одинаковым значением хеш-функции
28. Хеш-реализация по указанным `k` первым цифрам номера телефона на базе AVL дерева объектов с одинаковым значением хеш-функции
29. Хеш-реализация по указанным `k` последним буквам имени на базе AVL дерева объектов с одинаковым значением хеш-функции
30. Хеш-реализация по указанным `k` последним цифрам номера телефона на базе AVL дерева объектов с одинаковым значением хеш-функции
31. Хеш-реализация по сумме букв имени по указанному модулю `k` на базе AVL дерева объектов с одинаковым значением хеш-функции
32. Хеш-реализация по сумме цифр номера телефона по указанному модулю `k` на базе AVL дерева объектов с одинаковым значением хеш-функции
33. Хеш-реализация по указанным `k` первым буквам имени на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции
34. Хеш-реализация по указанным `k` первым цифрам номера телефона на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции
35. Хеш-реализация по указанным `k` последним буквам имени на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции
36. Хеш-реализация по указанным `k` последним цифрам номера телефона на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции
37. Хеш-реализация по сумме букв имени по указанному модулю `k` на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции
38. Хеш-реализация по сумме цифр номера телефона по указанному модулю `k` на базе красно-чёрного дерева объектов с одинаковым значением хеш-функции

---

## Файл `config.txt`

Значения дополнительных параметров `k`, `m`, если они есть в алгоритме, должны считываться из файла с фиксированным именем `config.txt`, который находится в том же каталоге, что и исполняемый файл.

### Формат файла

* Строки, начинающиеся с символа `#`, игнорируются и служат для комментариев.
* Пустые строки, содержащие только пробельные символы и символ `\n`, игнорируются.
* Параметрами являются целые числа, разделённые пробельными символами или `\n`.
* Пробельные символы: пробел, табуляция.
* Концом ввода параметров считается конец файла.

### Пример файла

```text
# Число букв имени в хеш функции (если она есть)
3

# Длина динамического вектора по имени (если он есть)
512

# Число цифр телефона в хеш функции (если она есть)
3

# Длина динамического вектора по телефону (если он есть)
512
```

---

## Пример кода для формирования полного пути к конфигурационному файлу

```cpp
#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <memory>

const char * config_name = "config.txt";

unique_ptr<char []> exe_path = make_unique<char []> (strlen (argv[0]) + 1);
strcpy (exe_path.get (), argv[0]); // make a copy, "dirname" modifies argument

char *dir = dirname (exe_path.get ()); // get directory with executable
printf ("Executable dir = %s\n", dir);

size_t path_len = strlen (dir) + 1 + strlen (config_name) + 1;
unique_ptr<char []> config_path = make_unique<char []> (path_len);

snprintf (config_path.get (), path_len, "%s/%s", dir, config_name);
printf ("Config path = %s\n", config_path.get ());
```

