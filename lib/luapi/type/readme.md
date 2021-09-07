# lib.luapi.type : lib.object `(module)`

## Parsed tagged comment block of any type

## Fields

- 📝 **name** ( string )
	`First word after tag =`
- 📝 **parent** ( string )
	`Text in parentheses after tag =`
- 📝 _title_ ( string = *nil* )
	`Any text at the end of tag = or 1st line in block`
- 📝 _square_ ( string = *nil* )
	`Text in square brackets after tag =`
- 📝 _description_ ( string = *nil* )
	`Not tagged lines in block`
- 👨‍👦 _returns_ ( list=lib.luapi.type#line|lib.luapi.type = *nil* )
	`Line after <`
- 👨‍👦 _fields_ ( list=lib.luapi.type#line|lib.luapi.type = *nil* )
	`Line after >`
- 👨‍👦 _locals_ ( list=lib.luapi.type#line|lib.luapi.type = *nil* )
	`Local types (module only)`
- 💡 **parse** ( function )
	`Parse block`
- 💡 **init** ( function )
	`Take comments block and return a type`
- 💡 **build_output** ( function )
	`Build markdown output for module-types`
- 💡 **correct** ( function )
	`Correct parsed block`

## Locals

- 📦 **line** ( table )
	`One line of tagged block`

## Details

### line `(table)`

One line of tagged block

Fields:

- 📝 _name_ ( string = *nil* )
	`First word after tag`
- 📝 _parent_ ( string = *nil* )
	`Text in parentheses`
- 📝 _title_ ( string = *nil* )
	`Any text at the end`
- 📝 _square_ ( string = *nil* )
	`Text in square brackets`
- 🧮 _index_ ( integer = *nil* )
	`Output order`

---

### build_output `(function)`

Build markdown output for module-types

> There are 2 different templates for composite and simple types:
>
> #### Composite (classes, tables, functions)
>
> + Header
> + Example    (spoiler)
> + Readme
> + Components (short list with links to Details)
> + Locals     (short list with links to Details)
> + Details    (full descriptions for everything)
> + Footer
>
> #### Simple (everything else)
>
> + Header
> + Readme
> + Example   (no spoiler)
> + Footer

Arguments:

- 👨‍👦 **file** ( lib.luapi.file )

---

### parse `(function)`

Parse block

Arguments:

- 👨‍👦 **self** ( lib.luapi.type )
- 📝 **block** ( string )
- 📝 _reqpath_ ( string = *nil* )

---

### init `(function)`

Take comments block and return a type

Arguments:

- 👨‍👦 **self** ( lib.luapi.type )
- 📝 _block_ ( string = *nil* )
- 📝 _reqpath_ ( string = *nil* )

---

### correct `(function)`

Correct parsed block

> Trim and remove empty strings in table values

Arguments:

- 📦 **self** ( table )

## Navigation

[Back to top of the document](#libluapitype--libobject-module)

[Back to upper directory](..)

[Back to project root](../../..)
