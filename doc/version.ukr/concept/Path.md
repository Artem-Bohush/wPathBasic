# Види шляхів

Рядок, що ідентифікує файл, шляхом перерахунку файлів котрі містять даний безпосередньо або опосередковано, називається - `шляхом`.

Зазвичай складові шляху розділяються слешом `/`, наприклад:

```
dir1/dir2/Terminal1.txt
```

Директорія `dir1` містить директорію `dir2`, котра містить ( ймовірно ) термінальний файл `Terminal.txt`.

Шляхи бувають:

- `глобальними` / `локальними`
- `абсолютними` / `відносними`
- `нормальними` / `канонічними` / `ненормальними` / `нативними`

### Глобальний шлях

Це абсолютний або відносний шлях до файлу, який містить протокол, зокрема може містити порожній протокол.

Протокол відділяється від решти шляху за допомогою `://`. Загальний вигляд глобального шляху - `{-protocol name-}://{-local path-}`. Назва протоколу може бути порожнім рядком, тобто шлях вигляду - `://`, є глобальним та валідним.

```
http://google.com
```

Протокол `http`, а решта шляху `google.com`.

### Локальний шлях

Це абсолютний або відносний шлях до файлу, який не містить назви протоколу.

```
/dir1/Termina.txt
```

Такий шлях не є глобальним бо не містить інформації про протокол.

### Абсолютний шлях

Це шлях, який починається із кореневої директорії.

Коренева директорія позначається, як `/`. Шляхи, котрі починаються із `/` є абсолютними.

```
/dir/Termina.txt
```

Такий шлях є абсолютним, оскільки починається із `/`. Також він є локальним.

```
file:///dir/Termina.txt
```

Інший приклад абсолютного шляху. На відмінно від першого такий шлях ще є і глобальним.

### Відносний шлях

Це шлях, який визначає місце розташування файлу відносно іншого файлу, а не відносно кореня і не починається із кореня.

Відносний шлях може знаходиться відносно кореня. Але навіть в такому разі він не починається із токена кореня.

```
dir/Termina.txt
```

Першим символом в рядку не є `/`, а отже він відносний.

### Приклади шляхів

Необхідно вказати на файл - /home/doc/myFile.txt

||Абсолютний|Відносний|
|:-:|:-:|:-:|
|Глобальний|file:///home/doc/myFile.txt|file://doc/myFile.txt|
|Локальний|/home/doc/myFile.txt|doc/myFile.txt|

### Нормальний шлях

Це шлях, приведений до форми, в якій шлях унікально ідентифікує файл із можливість диференціації директорії.

Два дуже різні за формою шляхи можуть вказувати на один і той файл, наприклад:

```
dir1/dir2/Terminal.txt
./dir1/dir2/dir3/../Terminal.txt
```

Це позбавляє можливості отримати відповідь на питання чи шляхи ідентифікують один і той же файл порівнянням рядків. Нормалізація вирішує цю проблему. Порівнюючи два нормалізованих шляхи можливо дати відповідь на питання, чи вони ведуть до одного і того ж файлу ( при умові, що в шляху нема лінків ). Також нормалізація прибирає специфічні для платформи чи операційної системи нюанси, що гарантує крос-платформенність програми, що розробляється.

Для нормалізації шляху використовуйте рутину `_.path.normalize()`. В процесі нормалізації з шляху видаляються при можливості '..' та '.', замінюються зворотні слеші на звичайні та робляться ескейп спеціальних символів.

```js
let path1 = _.path.normalize( 'C:\\project\\index.html\\..\\.' );
console.log( path1 );
// log : /C/project

let path2 = _.path.normalize( '/C/dir1/../project' );
console.log( path2 );
// log : /C/project

console.log( path1 === path2 );
// log : true
```

В наслідок нормалізації двох різних за формою шляхів `C:\\project\\index.html\\..\\.` та `/C/dir1/../project` з'ясувалося, що вони ідентифікують один і той самий файл.

### Канонічний шлях

Це шлях, приведений до форми, в якій шлях унікально ідентифікує файл без можливості диференціації директорії.

`Канонізація` шляху - це процес аналогічний до нормалізації, проте шлях у канонічній формі є більш строгим та простим. Єдина відмінність алгоритму канонізації від алгоритму нормалізації полягає в тому, що канонізація здійснює додатковий крок прибирання слеша в кінці шляху, що робить неможливим диференціацію директорій.

```js
let normal = _.path.normalize( 'foo/../bar/baz/' );
console.log( normal );
// bar/baz/

let cononical1 = _.path.canonize( 'foo/../bar/baz/' );
console.log( cononical1 );
// bar/baz

let cononical2 = _.path.canonize( 'foo/../bar/baz' );
console.log( cononical2 );
// bar/baz

console.log( cononical1 === cononical2 );
// log : true
```

Шляхи `cononical1` та `cononical2` стали однаковими після канонізації, тоді як нормалізація зберегла останній слеш для шляху `foo/../bar/baz/`.

Слеш після шляху можливо використати, як додатковий канал інформації, наприклад для диференціації тих файлів які є директоріями.

### Нативний шлях

Це шлях, яким має вигляд, характерний для якоїсь операційної системи, платформи чи інтерпретатора.

Мета процесу `нативізації` полягає в приведенні шляху у форму зрозумілу певній операційній системі, платформі чи інтерпретатору.

Для нативізації використовуйте рутину `_.path.nativize()`.

```js
// process.platform === 'win32'
let native = '/C/Newsletters/Summer2018.pdf';
console.log( _.path.nativize( native ) );
// C:\Newsletters\Summer2018.pdf
```

Приведення нормального шляху `/C/Newsletters/Summer2018.pdf` до зрозумілої для `Windows` форми `C:\Newsletters\Summer2018.pdf`.

[Повернутись до змісту](../README.md#концепції)