# Argon
Argon is a simple compiled HTML text macro language, with a focus on minimalism and readability. It was created out of frustration using vibe.d's Diet Templates.
Argon is simple to use, in that it is does not try to abstract over HTML syntax, rather it provides a simple to use text interpolation system, which can easily integrate into existing data structures.

## Features:
* Namespaces - All elements require a namespace to access a data structure from, so it is easy to put multiple datastructures in one page.
* Lists - Lists allow for iteration over data structures which can be iterated with `foreach`, along with arbitrary bits of HTML, other elements and nested lists.
* Compiled - Argon templates compile down to D code, for maximum efficiency.
* Includes - Argon templates can include each other, and included templates have full access to all of the main templates namespaces.

## TODO:
* White Space Control - Better white space control for argon templates.
* Include Indenting - Support for indenting HTML source in included templates.
* Dynamic Render - Support for dynamic rendering of Argon templates.
* Conditional Rendering - Support for conditional rendering of parts of Argon templates.
* Automatic Encoding - Support for automatic encoding of elements to HTML escape sequences.

## Example:
The Following is an example of how to use an Argon template. See the examples directory for further details.

### test.argon:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>{element=content:hello_world}</title>
  </head>
  <body>
    <h1>{element=content:hello_world}</h1>
    <ul>
    {list=content:list}
      <li>list index: '{element=content:list[#]}', list value: '{element=content:list[$]}'</li>
    {/list}
    </ul>
  </body>
 </html>
 ```

### test.d:
```d
import std.stdio;
import argon.compiler;

struct Content
{
  string hello_world = "Hello, World!";
  string[] list = ["alpha", "beta", "gamma", "delta"];
}

void main()
{
  Content content;
  stdout.renderArgonTemplate!("test.argon", "content", content)();
}
```