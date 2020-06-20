# Види шляхів
Шлях - набір символів, що показує розташування файлу або каталогу в файловій системі.

**Шляхи бувають:**

- `глобальними` або `локальними`
- `абсолютними` або `відносними`
- `канонічними`, `нормальними` або `ненормальними`

### Глобальний та локальний шлях
Глобальний шлях - це шлях до файлу, який містить у собі протокол - ім'я сайту в мережі, підкаталог(або кілька підкаталогів), 
назва файлу. Тобто необхідний файл знаходиться на віддаленому ресурсі.

Локальний шлях - це шлях до файлу, що знаходиться на локальному комп'ютері, звідки виконується запит. У такому шляху 
протокол не вказується.

### Абсолютний та відносний шлях
Абсолютний шлях - це шлях, який вказує на одне і те ж місце в файловій системі, незалежно від поточного робочого каталогу 
або інших обставин. Абсолютний шлях завжди починається з кореневого каталогу. 
В операційних системах UNIX це "/", у Windows -"C:\\".

Відносний шлях - це шлях відносно поточного робочого каталогу користувача або активних додатків. Відносний шлях
ніколи не починається із кореневого каталогу.

Приклади шляхів.

Необхідно вказати на файл - /home/john/documents/myFile.txt

- Глобальний шлях:
  - абсолютний -> file:///home/john/documents/myFile.txt
  - відносний -> file://documents/myFile.txt

- Локальний шлях:
  - абсолютний -> /home/john/documents/myFile.txt
  - відносний -> documents/myFile.txt

<!--  -->

### Нормалізований шлях

Нормалізація шляху - це процес, при якому шлях приводиться до однакового вигляду, мета якого полягає в перетворенні
шляху в нормалізований вигляд, з тим, щоб визначити еквівалентність двох синтаксично різних шляхів.

Рутина `normalize` нормалізує шлях, шляхом видалення надлишкових роздільників, опрацюванням '..' та '.' сегментів так,
що A//B, A/./B та A/foo/../B - всі приводяться до A/B. Така маніпуляція рядком може змінити значення шляху, 
що містить символічні посилання.

Видалення "." в середині та у кінці шляху:
```js
let path = ':///some/staging/./index.html/./';
console.log( _.uri.normalize( path ) ); 
// :///some/staging/index.html/
```

```js
let path = '://some/staging/index.html/.';
console.log( _.uri.normalize( path ) ); 
// ://some/staging/index.html
```
Видалення ".." та директорії перед ним:
```js
let path = '/foo/bar//baz1/baz2//some/..';
console.log( _.uri.normalize( path ) ); 
// /foo/bar//baz1/baz2/
```
Видалення комбінації "." та "..":
```js
let path = 'https://web.archive.org/web/*\/http://www.heritage.org/.././index/ranking/./.';
console.log( _.uri.normalize( path ) ); 
// https://web.archive.org/web/*\/http://index/ranking
```
Заміна "\\" на "/":
```js
let path = 'C:\\Projects\\apilibrary\\index.html\\..\\';
console.log( _.uri.normalize( path ) ); 
// /C/Projects/apilibrary/
```

### Нативізований шлях

Мета процесу нативізації полягає в приведенні шляху в нативізований вигляд, з тим, щоб 
визначити еквівалентний шлях в ОС на якій виконується процес, до заданого.

Рутина `nativize` виконує нативізацію шляхів, як показано нижче.

Якщо нативізація виконується на Windows, то в результаті:

абсолютні шляхи починаються - C:\\dir\\...
```js
// process.platform === 'win32'
let path = '/A';
console.log( _.uri.nativize( path ) ); 
// A:\
```
```js
// process.platform === 'win32'
let path = '/C/Documents/Newsletters/Summer2018.pdf';
console.log( _.uri.nativize( path ) ); 
// C:\Documents\Newsletters\Summer2018.pdf
```
Заміна "/" на "\\":
```js
// process.platform === 'win32'
let path = '/Documents/Newsletters/Summer2018.pdf';
console.log( _.uri.nativize( path ) ); 
// \Documents\Newsletters\Summer2018.pdf
```
Виконання нативізації на ОС відмінній від Windows не призводить до жодних змін шляху.
```js
// process.platform !== 'win32'
let path = '/bin';
console.log( _.uri.nativize( path ) ); 
// /bin
```

```js
// process.platform !== 'win32'
let path = '/home/mthomas/class_stuff/foo';
console.log( _.uri.nativize( path ) ); 
// /home/mthomas/class_stuff/foo
```

### Канонічний шлях

Канонізація шляху - це процес аналогічний до нормалізації, проте шлях у канонічній формі є більш строгим та простим.
Рутина `canonize` повертає шлях без "/" у кінці, якщо такий був до цього.

Видалення "\\" у кінці шляху:
```js
path = '/C:\\temp\\\\foo\\bar\\';
console.log( _.uri.canonize( path ) ); 
// /C:/temp//foo/bar
```
Видалення ".." із директорією перед ним та "/" у кінці шляху:
```js
let path = '/C:\\temp\\\\foo\\\\bar\\..\\';
console.log( _.uri.canonize( path ) ); 
// /C:/temp//foo
```
Видалення "." та "/" у кінці шляху:
```js
let path = 'foo/././bar/././baz/';
console.log( _.uri.canonize( path ) ); 
// foo/bar/baz
```
